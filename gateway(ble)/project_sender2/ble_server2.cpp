#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include "mbedtls/aes.h"
#include "esp_gap_ble_api.h"
#include <DHT.h>
#include <Wire.h>

// BLE service and characteristic UUIDs for Sender 2
#define SERVICE_UUID2 "87654321-4321-4321-4321-ba0987654321"
#define CHAR_UUID2    "dcba4321-8765-09ab-fedc-0987654321ba"

// DHT11 setup (connected to GPIO 21)
#define DHTPIN 21
#define DHTTYPE DHT11

// Define your I2C oxygen sensor address (example address, adjust as needed)
#define OXYGEN_SENSOR_ADDR 0x5A

const char *aes_key = "1234567890abcdef";  // 16-byte AES key
const char *aes_iv  = "abcdef1234567890";   // 16-byte IV
uint32_t BLE_PASSKEY = 123456;

BLECharacteristic* pCharacteristic;
DHT dht(DHTPIN, DHTTYPE);

// Encrypt input using AES-128-CBC with PKCS#7 padding.
void encryptAES_CBC(const char *input, size_t input_len, uint8_t *output, size_t &output_len) {
  mbedtls_aes_context aes;
  mbedtls_aes_init(&aes);
  mbedtls_aes_setkey_enc(&aes, (const unsigned char *)aes_key, 128);

  // Create a temporary IV copy.
  unsigned char iv_copy[16];
  memcpy(iv_copy, aes_iv, 16);

  // Calculate padded length (multiple of 16 bytes)
  size_t padded_len = ((input_len + 15) / 16) * 16;
  char padded[128] = {0};
  memcpy(padded, input, input_len);

  // PKCS#7 padding: fill remainder with the pad value.
  uint8_t pad_value = padded_len - input_len;
  for (int i = input_len; i < padded_len; i++) {
    padded[i] = pad_value;
  }

  mbedtls_aes_crypt_cbc(&aes, MBEDTLS_AES_ENCRYPT, padded_len, iv_copy,
                        (const unsigned char *)padded, output);

  output_len = padded_len;
  mbedtls_aes_free(&aes);
}

void bleSecuritySetup() {
  esp_ble_auth_req_t auth_req = ESP_LE_AUTH_REQ_SC_BOND;
  esp_ble_io_cap_t iocap = ESP_IO_CAP_OUT;
  uint8_t key_size = 16;
  uint8_t init_key = ESP_BLE_ENC_KEY_MASK | ESP_BLE_ID_KEY_MASK;
  uint8_t resp_key = ESP_BLE_ENC_KEY_MASK | ESP_BLE_ID_KEY_MASK;

  esp_ble_gap_set_security_param(ESP_BLE_SM_AUTHEN_REQ_MODE, &auth_req, sizeof(uint8_t));
  esp_ble_gap_set_security_param(ESP_BLE_SM_IOCAP_MODE, &iocap, sizeof(uint8_t));
  esp_ble_gap_set_security_param(ESP_BLE_SM_MAX_KEY_SIZE, &key_size, sizeof(uint8_t));
  esp_ble_gap_set_security_param(ESP_BLE_SM_SET_INIT_KEY, &init_key, sizeof(uint8_t));
  esp_ble_gap_set_security_param(ESP_BLE_SM_SET_RSP_KEY, &resp_key, sizeof(uint8_t));
}

void setup() {
  Serial.begin(115200);
  // Initialize DHT11 sensor.
  dht.begin();
  // Initialize I²C on SDA=15, SCL=33.
  Wire.begin(15, 33);

  BLEDevice::init("SecureServer2");
  bleSecuritySetup();

  BLEServer *pServer = BLEDevice::createServer();
  // Create service using SERVICE_UUID2
  BLEService *pService = pServer->createService(SERVICE_UUID2);

  // Add the service UUID to the advertising data.
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID2);

  pCharacteristic = pService->createCharacteristic(
    CHAR_UUID2,
    BLECharacteristic::PROPERTY_NOTIFY
  );

  pService->start();
  pAdvertising->start();
  Serial.println("📡 Advertising started (Sender2)");
}

void loop() {
  // Read temperature and humidity from DHT11.
  float t = dht.readTemperature();
  float h = dht.readHumidity();
  // Read oxygen level from the oxygen sensor.
  float oxygen = 0;
  Wire.beginTransmission(OXYGEN_SENSOR_ADDR);
  Wire.endTransmission();
  Wire.requestFrom(OXYGEN_SENSOR_ADDR, 2);
  if (Wire.available() >= 2) {
    uint16_t raw = (Wire.read() << 8) | Wire.read();
    oxygen = raw / 100.0;  // Example conversion, adjust as needed.
  } else {
    oxygen = 21.0;  // Fallback value.
  }

  if (isnan(t) || isnan(h)) {
    Serial.println("⚠️ DHT11 read failed. Skipping...");
    delay(2000);
    return;
  }

  // Build the full JSON string.
  char json[128];
  // Example JSON: {"temp":23.4,"hum":56,"oxy":21.3}
  snprintf(json, sizeof(json), "{\"temp\":%.1f,\"hum\":%.0f,\"oxy\":%.1f}", t, h, oxygen);
  Serial.print("📤 Plain JSON: ");
  Serial.println(json);

  uint8_t encrypted[128];
  size_t encrypted_len = 0;
  encryptAES_CBC(json, strlen(json), encrypted, encrypted_len);

  // Send the encrypted data via BLE notify.
  pCharacteristic->setValue(encrypted, encrypted_len);
  pCharacteristic->notify();

  Serial.print("🔐 Encrypted (");
  Serial.print(encrypted_len);
  Serial.print(" bytes): ");
  for (int i = 0; i < encrypted_len; i++) {
    Serial.printf("%02X ", encrypted[i]);
  }
  Serial.println();

  delay(2000);
}

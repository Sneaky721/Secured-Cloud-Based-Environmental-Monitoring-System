#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include "mbedtls/aes.h"
#include "esp_gap_ble_api.h"
#include <DHT.h>

#define SERVICE_UUID "12345678-1234-1234-1234-1234567890ab"
#define CHAR_UUID    "abcd1234-5678-90ab-cdef-1234567890ab"

#define DHTPIN 33
#define DHTTYPE DHT22
#define LIGHT_SENSOR_PIN 4

const char *aes_key = "1234567890abcdef"; // 16 bytes
const char *aes_iv  = "abcdef1234567890"; // 16 bytes
uint32_t BLE_PASSKEY = 123456;

BLECharacteristic* pCharacteristic;
DHT dht(DHTPIN, DHTTYPE);

void encryptAES_CBC(const char *input, size_t input_len, uint8_t *output, size_t &output_len) {
  mbedtls_aes_context aes;
  mbedtls_aes_init(&aes);
  mbedtls_aes_setkey_enc(&aes, (const unsigned char *)aes_key, 128);

  unsigned char iv_copy[16];
  memcpy(iv_copy, aes_iv, 16);

  // Pad to multiple of 16 bytes using PKCS#7
  size_t padded_len = ((input_len + 15) / 16) * 16;
  char padded[64] = {0};
  memcpy(padded, input, input_len);

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
  dht.begin();
  BLEDevice::init("SecureServer");
  bleSecuritySetup();

  BLEServer *pServer = BLEDevice::createServer();
  
  // Create the service using the defined SERVICE_UUID.
  BLEService *pService = pServer->createService(SERVICE_UUID);
  
  // Add the service UUID to the advertising data.
  BLEAdvertising *pAdvertising = BLEDevice::getAdvertising();
  pAdvertising->addServiceUUID(SERVICE_UUID);

  pCharacteristic = pService->createCharacteristic(
    CHAR_UUID,
    BLECharacteristic::PROPERTY_NOTIFY
  );

  pService->start();
  pAdvertising->start();
  Serial.println("📡 Advertising started");
}

void loop() {
  float t = dht.readTemperature();
  float h = dht.readHumidity();
  int light = analogRead(LIGHT_SENSOR_PIN);

  if (isnan(t) || isnan(h)) {
    Serial.println("⚠️ DHT22 read failed. Skipping...");
    delay(2000);
    return;
  }

  // Build JSON
  char json[64];
  snprintf(json, sizeof(json), "{\"temp\":%.1f,\"hum\":%.0f,\"light\":%d}", t, h, light);
  Serial.print("📤 Plain JSON: ");
  Serial.println(json);

  // Encrypt JSON
  uint8_t encrypted[64];
  size_t encrypted_len = 0;
  encryptAES_CBC(json, strlen(json), encrypted, encrypted_len);

  // Send encrypted data via BLE notify
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

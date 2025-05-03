#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEClient.h>
#include <BLEScan.h>
#include "esp_gap_ble_api.h"
#include "mbedtls/aes.h"

// For SecureServer (first sender)
#define SERVICE_UUID      "12345678-1234-1234-1234-1234567890ab"
#define CHAR_UUID         "abcd1234-5678-90ab-cdef-1234567890ab"

// For SecureServer2 (second sender) – different UUIDs
#define SERVICE_UUID2     "87654321-4321-4321-4321-ba0987654321"
#define CHAR_UUID2        "dcba4321-8765-09ab-fedc-0987654321ba"

const char *aes_key = "1234567890abcdef";  // 16-byte AES key
const char *aes_iv  = "abcdef1234567890";   // 16-byte IV
uint32_t BLE_PASSKEY = 123456;

// Global pointers for connections.
BLEClient *pClient1 = nullptr;  // For device advertising SERVICE_UUID (SecureServer)
BLEClient *pClient2 = nullptr;  // For device advertising SERVICE_UUID2 (SecureServer2)
BLERemoteCharacteristic *pChar1 = nullptr;
BLERemoteCharacteristic *pChar2 = nullptr;

// Global pointers for target devices.
BLEAdvertisedDevice *targetDevice1 = nullptr; // Device that advertises SERVICE_UUID.
BLEAdvertisedDevice *targetDevice2 = nullptr; // Device that advertises SERVICE_UUID2.

//---------------------------------------------------
// AES decryption function using AES-128-CBC with PKCS#7 unpadding.
void decryptAES_CBC(const uint8_t *input, size_t length, char *output) {
  mbedtls_aes_context aes;
  mbedtls_aes_init(&aes);
  mbedtls_aes_setkey_dec(&aes, (const unsigned char *)aes_key, 128);
  
  // Make a temporary IV copy because CBC modifies it.
  unsigned char iv_copy[16];
  memcpy(iv_copy, aes_iv, 16);
  
  mbedtls_aes_crypt_cbc(&aes, MBEDTLS_AES_DECRYPT, length, iv_copy, input, (unsigned char *)output);
  output[length] = '\0'; // Temporary null termination
  
  // Remove PKCS#7 padding: the last byte value is the number of padding bytes.
  uint8_t pad = output[length - 1];
  if (pad > 0 && pad <= 16) {
    output[length - pad] = '\0';
  }
  mbedtls_aes_free(&aes);
}

//---------------------------------------------------
// Notification callback for SecureServer (Server1)
void notifyCallback1(BLERemoteCharacteristic *pCharacteristic,
                     uint8_t *data, size_t length, bool isNotify) {
  if (length % 16 != 0 || length == 0) {
    Serial.printf("Server1: Invalid encrypted length: %d (must be multiple of 16)\n", (int)length);
    return;
  }
  char decrypted[128] = {0}; // Adjust buffer size if needed.
  decryptAES_CBC(data, length, decrypted);
  Serial.print("Server1 Decrypted JSON: ");
  Serial.println(decrypted);
}

//---------------------------------------------------
// Notification callback for SecureServer2 (Server2)
void notifyCallback2(BLERemoteCharacteristic *pCharacteristic,
                     uint8_t *data, size_t length, bool isNotify) {
  if (length % 16 != 0 || length == 0) {
    Serial.printf("Server2: Invalid encrypted length: %d (must be multiple of 16)\n", (int)length);
    return;
  }
  char decrypted[128] = {0};
  decryptAES_CBC(data, length, decrypted);
  Serial.print("Server2 Decrypted JSON: ");
  Serial.println(decrypted);
}

//---------------------------------------------------
// Advertised device callback: only saves devices that advertise the target services.
class MyAdvertisedDeviceCallbacks : public BLEAdvertisedDeviceCallbacks {
public:
  virtual ~MyAdvertisedDeviceCallbacks() {}
  void onResult(BLEAdvertisedDevice advertisedDevice) override {
    // Check for target service UUIDs.
    if (advertisedDevice.isAdvertisingService(BLEUUID(SERVICE_UUID))) {
      targetDevice1 = new BLEAdvertisedDevice(advertisedDevice);
      Serial.println("-> Target device with SERVICE_UUID (SecureServer) found.");
    }
    if (advertisedDevice.isAdvertisingService(BLEUUID(SERVICE_UUID2))) {
      targetDevice2 = new BLEAdvertisedDevice(advertisedDevice);
      Serial.println("-> Target device with SERVICE_UUID2 (SecureServer2) found.");
    }
  }
};

//---------------------------------------------------
// BLE security setup.
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

//---------------------------------------------------
void setup() {
  Serial.begin(115200);
  Serial.println("Scanning for target BLE devices by service UUID...");

  BLEDevice::init("MultiClient");
  bleSecuritySetup();
  
  BLEScan *pScan = BLEDevice::getScan();
  pScan->setAdvertisedDeviceCallbacks(new MyAdvertisedDeviceCallbacks(), false);
  pScan->setActiveScan(true);
  
  // Repeatedly scan (5-second intervals) until both target devices are found.
  while (targetDevice1 == nullptr || targetDevice2 == nullptr) {
    pScan->start(5, false);
    Serial.println("Continuing scan...");
    delay(2000);
  }
  Serial.println("Both target devices found. Connecting...");
  
  // Connect to device advertising SERVICE_UUID (SecureServer).
  pClient1 = BLEDevice::createClient();
  Serial.println("Connecting to device with SERVICE_UUID (SecureServer)...");
  if (pClient1->connect(targetDevice1)) {
    pClient1->setMTU(517);
    Serial.print("MTU for Server1: ");
    Serial.println(pClient1->getMTU());
    BLERemoteService *pService1 = pClient1->getService(BLEUUID(SERVICE_UUID));
    if (pService1 != nullptr) {
      pChar1 = pService1->getCharacteristic(BLEUUID(CHAR_UUID));
      if (pChar1 != nullptr && pChar1->canNotify()) {
        pChar1->registerForNotify(notifyCallback1);
        Serial.println("Notification callback registered for SecureServer.");
      } else {
        Serial.println("Error: Characteristic not available or not notifiable on SecureServer.");
      }
    } else {
      Serial.println("Error: Service not found on SecureServer.");
    }
  } else {
    Serial.println("Error: Could not connect to SecureServer.");
  }
  
  // Connect to device advertising SERVICE_UUID2 (SecureServer2).
  pClient2 = BLEDevice::createClient();
  Serial.println("Connecting to device with SERVICE_UUID2 (SecureServer2)...");
  if (pClient2->connect(targetDevice2)) {
    pClient2->setMTU(517);
    Serial.print("MTU for Server2: ");
    Serial.println(pClient2->getMTU());
    BLERemoteService *pService2 = pClient2->getService(BLEUUID(SERVICE_UUID2));
    if (pService2 != nullptr) {
      pChar2 = pService2->getCharacteristic(BLEUUID(CHAR_UUID2));
      if (pChar2 != nullptr && pChar2->canNotify()) {
        pChar2->registerForNotify(notifyCallback2);
        Serial.println("Notification callback registered for SecureServer2.");
      } else {
        Serial.println("Error: Characteristic not available or not notifiable on SecureServer2.");
      }
    } else {
      Serial.println("Error: Service not found on SecureServer2.");
    }
  } else {
    Serial.println("Error: Could not connect to SecureServer2.");
  }
}

void loop() {
  // All notifications are handled via callbacks.
  delay(1000);
}

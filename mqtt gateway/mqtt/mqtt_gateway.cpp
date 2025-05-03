/*****************************************************************
 *  ESP32  ►  Wi‑Fi  ►  MQTT (TLS)  ►  publishes dummy JSON
 *
 *  Topics:
 *      data/server1   {"temp":..,"hum":..,"light":..}
 *      data/server2   {"temp":..,"hum":..,"oxy":..}
 *****************************************************************/
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <PubSubClient.h>

/************ Wi‑Fi credentials ************/
const char* WIFI_SSID = "Wifi_SSID";
const char* WIFI_PASS = "wifi_passwprd";

/************ MQTT (TLS) settings ************/
const char* MQTT_HOST = "IP of HOST";
const uint16_t MQTT_PORT = 8883;          // TLS listener
const char* MQTT_USER = "testuser";
const char* MQTT_PASS = "mypassword";
const char* TOPIC1 = "data/server1";
const char* TOPIC2 = "data/server2";

/************ (Optional) broker root‑CA ************/
static const char CA_CERT[] PROGMEM = R"EOF(
-----BEGIN CERTIFICATE-----
MIIDDTCCAfWgAwIBAgIUBBOq64qFYerT/8rHgF3xi4TJ8f8wDQYJKoZIhvcNAQEL
BQAwFjEUMBIGA1UEAwwLcmFzcGJlcnJ5cGkwHhcNMjUwNDEzMTkxNzM2WhcNMjYw
NDEzMTkxNzM2WjAWMRQwEgYDVQQDDAtyYXNwYmVycnlwaTCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBAMFw4h97qUWXf8wmgFdZKNjDddmediF9fAzHIB9F
JkAGZUWDLGrBw+xhqpPgW0vWRoiel1KIVTKKlyjANIUcsfGUhFHIP5NHzVeGgCq0
GJgCBrRvQAfBCTiD0OIQeQcFefSco2MGX14iqVuLdf/DDqeHC64jaL8bZnztVoUc
X1NOCABPI9+lZXz7iSLrJmvL9gG13uY9JPjdwoonmyNIvbFhupTUY2uAq/EuXMl5
zTXVrEQ+EQ/N9mHQFtmaAr0jwNIQSDyq1C/7nkppFiGOzAU2RdfRDJ7N6CIjGq6c
JMliCW+RCwq+fErOisUJwBd9JaJA9daJ7FEnj0GmRleEPx0CAwEAAaNTMFEwHQYD
VR0OBBYEFIu91iS/F9cIL1Ko6aj1V/U3LSUWMB8GA1UdIwQYMBaAFIu91iS/F9cI
L1Ko6aj1V/U3LSUWMA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEB
AF9XfnZvxfGdWNDOihDU3wEuwOops1oTr4xClgWAedvil2mSq9P46lN6BqWNpDf4
MdomoETH0xw02v/BH6cYb+4FQndrLao5z3/53gfpbY1MIgub3uOMCaUVL0to0RCI
9v1qbXL4a2iHr6NBSW02sv0ehMG/Tac5djBYZu3rsyReZReDuKtdzlBCDHIs8Oxd
3iW5h6VrWPa+TlKRfgOVsP2l9MKH8HaHFblHZcFxHPxqMl/3RnOjQHEeq4pB6GdJ
xc/Wac1Kc0Yg2QtCXTQLLyg8vQOKaxrX34422nNL4Yi+iIQ4OgSpkVhe341sag+U
5jT2I5HGi64PtGKiOLYLYhA=
-----END CERTIFICATE-----
)EOF";

/************ Globals ************/
WiFiClientSecure tls;
PubSubClient     mqtt(tls);

/************ Helpers ************/
void wifiConnect() {
  WiFi.begin(WIFI_SSID, WIFI_PASS);
  Serial.print("Wi‑Fi");
  while (WiFi.status() != WL_CONNECTED) { Serial.print('.'); delay(500); }
  Serial.print("    IP: "); Serial.println(WiFi.localIP());
}

void mqttConnect() {
  // Comment out one of the two lines below:
  //tls.setCACert(CA_CERT);       
  tls.setInsecure();          

  mqtt.setServer(MQTT_HOST, MQTT_PORT);
  Serial.printf("MQTT → %s:%u ", MQTT_HOST, MQTT_PORT);
  while (!mqtt.connected()) {
    if (mqtt.connect("ESP32‑Dummy", MQTT_USER, MQTT_PASS)) {
      Serial.println("MQTT OK");
    } else {
      Serial.print('#'); delay(1000);
    }
  }
}

void publishDummy() {
  /* --- create dummy values --- */
  float temp  = random(200, 320) / 10.0;   // 20.0 – 32.0 °C
  int   hum   = random(30, 70);            // 30 – 70 %
  int   light = random(100, 400);          // 100 – 400 lux
  float oxy   = random(190, 220) / 10.0;   // 19.0 – 22.0 %

  char json1[64];
  snprintf(json1, sizeof(json1),
           "{\"temp\":%.1f,\"hum\":%d,\"light\":%d}", temp, hum, light);

  char json2[64];
  snprintf(json2, sizeof(json2),
           "{\"temp\":%.1f,\"hum\":%d,\"oxy\":%.1f}", temp+0.3, hum+1, oxy);

  mqtt.publish(TOPIC1, json1, true);
  mqtt.publish(TOPIC2, json2, true);

  Serial.print("→ "); Serial.print(TOPIC1); Serial.print("  "); Serial.println(json1);
  Serial.print("→ "); Serial.print(TOPIC2); Serial.print("  "); Serial.println(json2);
}

/********************* SETUP *********************/
void setup() {
  Serial.begin(115200); delay(200);
  wifiConnect();
  mqttConnect();
  randomSeed(esp_random());      // better randomness
}

/********************* LOOP *********************/
void loop() {
  if (!mqtt.connected()) mqttConnect();
  mqtt.loop();

  publishDummy();                // send every 5 s
  delay(6000);
}

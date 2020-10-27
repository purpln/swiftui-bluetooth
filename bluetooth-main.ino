#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>

BLEServer *pServer = NULL;
BLECharacteristic * pTxCharacteristic;
bool deviceConnected = false;
bool oldDeviceConnected = false;
uint8_t value = 0;
#define pin LED_BUILTIN
#define service_uuid "6E400001-B5A3-F393-E0A9-E50E24DCCA9E"
#define rx_uuid "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"
#define tx_uuid "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"

class MyServerCallbacks: public BLEServerCallbacks{
  void onConnect(BLEServer* pServer){
    deviceConnected = true;
  };
  void onDisconnect(BLEServer* pServer){
    deviceConnected = false;
    }
};
void values(uint8_t value) {
  char hex[2];
  sprintf(hex, "%02X", value);
  Serial.print(hex);
};

class MyCallbacks: public BLECharacteristicCallbacks {
  void onWrite(BLECharacteristic *pCharacteristic) {
    std::string rxValue = pCharacteristic->getValue();
    if (rxValue.length() >0) {
      for(int i=0; i<sizeof(rxValue); i++){
        values(rxValue[i]);
      }
      Serial.print("\n");
      //for (int i = 0; i < rxValue.length(); i++) Serial.print(rxValue[i]);
      //Serial.print("\n");
      value = rxValue[0];
    }
  }
};


void setup() {
  pinMode(pin, OUTPUT);
  Serial.begin(115200);
  BLEDevice::init("esp");
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());
  BLEService *pService = pServer->createService(service_uuid);
  pTxCharacteristic = pService->createCharacteristic(tx_uuid, BLECharacteristic::PROPERTY_NOTIFY);
  pTxCharacteristic->addDescriptor(new BLE2902());
  BLECharacteristic * pRxCharacteristic = pService->createCharacteristic(rx_uuid, BLECharacteristic::PROPERTY_WRITE);
  pRxCharacteristic->setCallbacks(new MyCallbacks());
  pService->start();
  pServer->getAdvertising()->start();
  Serial.println("waiting a client connection to notify...");
}

void loop(){
  if(deviceConnected){
    pTxCharacteristic->setValue(&value, 1);
    pTxCharacteristic->notify();
		delay(10);
	}
	if (value == 0x01){
	  digitalWrite(pin, 1);
  }else{
	  digitalWrite(pin, 0);
	}
 
	if (!deviceConnected && oldDeviceConnected) {
	  delay(500);
	  pServer->startAdvertising();
	  Serial.println("start advertising");
	  oldDeviceConnected = deviceConnected;
	}
	if (deviceConnected && !oldDeviceConnected) {
	  oldDeviceConnected = deviceConnected;
	}
}

module.exports = {
  title: "pimatic-aqara device config options"
  AqaraMotionSensor: {
    title: "AqaraMotionSensor config options"
    type: "object"
    extensions: ["xPresentLabel", "xAbsentLabel"]
    properties:
      SID:
        type: "string"
        required: true
      autoReset:
        description: "By default the sensor resets after 120s, if this takes to long for your, enable autoreset"
        type: "boolean"
        default: true
      resetTime:
        type: "integer"
        default: 60000
      lux:
        description: "If your using V1 of this sensor, disable lux"
        type: "boolean"
        default: true
      displaySparkline:
        description: "Show the sparkline for the lux value"
        type: "boolean"
        default: false
  }
  AqaraDoorSensor: {
    title: "AqaraDoorSensor config options"
    type: "object"
    extensions: ["xClosedLabel", "xOpenedLabel"]
    properties:
      SID:
        type: "string"
        required: true
  }
  AqaraLeakSensor: {
    title: "AqaraLeakSensor config options"
    type: "object"
    properties:
      SID:
        type: "string"
        required: true
      wet:
        type: "string"
        default: "wet"
      dry:
        type: "string"
        default: "dry"
  }
  AqaraWirelessSwitch: {
    title: "AqaraWirelessSwitch config options"
    type: "object"
    properties:
      SID:
        type: "string"
        required: true
  }
  AqaraWirelessButton: {
    title: "AqaraWirelessSwitch config options"
    type: "object"
    properties:
      SID:
        type: "string"
        required: true
      resetTime:
        type: "integer"
        default: 100
  }
  AqaraTemperatureSensor: {
    title: "AqaraTemperatureSensor config options"
    type: "object"
    properties:
      SID:
        type: "string"
        required: true
      pressure:
        description: "If your using V1 of this sensor, disable pressure"
        type: "boolean"
        default: true
  }
}

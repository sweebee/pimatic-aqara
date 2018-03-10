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
      resetTime:
        type: "integer"
        default: 30000
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
      Wet:
        type: "string"
        default: "wet"
      Dry:
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
  }
}

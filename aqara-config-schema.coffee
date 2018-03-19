module.exports = {
  title: "pimatic aqara config options"
  type: "object"
  properties:
    password:
      description: "Password for the gateway"
      type: "string"
    pairing:
      description: "Enable pairing when discovering devices"
      type: "boolean"
      default: true
    debug:
      description: "Log information for debugging, including received messages"
      type: "boolean"
      default: false
    batteryMin:
      description: "The low voltage when the battery is empty"
      type: "number"
      default: 2800
    batteryMax:
      description: "The high voltage when the battery is full"
      type: "number"
      default: 3200
}

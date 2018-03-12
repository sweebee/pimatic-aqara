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
}

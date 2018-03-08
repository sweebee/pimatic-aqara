module.exports = {
  title: "pimatic-aqara device config options"
  AqaraMotionSensor: {
    title: "AqaraMotionSensor config options"
    type: "object"
    extensions: ["xLink", "xPresentLabel", "xAbsentLabel"]
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
    extensions: ["xLink", "xClosedLabel", "xOpenedLabel"]
    properties:
      SID:
        type: "string"
        required: true
  }
  AqaraLeakSensor: {
    title: "AqaraLeakSensor config options"
    type: "object"
    extensions: ["xLink", "xPresentLabel", "xAbsentLabel"]
    properties:
      SID:
        type: "string"
        required: true
  }
}

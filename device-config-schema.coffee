module.exports = {
  title: "pimatic-aqara device config options"
  AqaraMotionSensor: {
    title: "AqaraMotionSensor config options"
    type: "object"
    extensions: ["xLink", "xPresentLabel", "xAbsentLabel"]
    properties:
      SID:
        type: "string"
      resetTime:
        type: "integer"
        default: 30000
  }
  AqaraLeakSensor: {
    title: "AqaraLeakSensor config options"
    type: "object"
    extensions: ["xLink", "xPresentLabel", "xAbsentLabel"]
    properties:
      SID:
        type: "string"
  }
}

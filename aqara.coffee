module.exports = (env) ->

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  LumiAqara = require './lumi-aqara'

  class aqara extends env.plugins.Plugin

    init: (app, @framework, @config) =>


      # Register devices
      deviceConfigDef = require("./device-config-schema.coffee")

      @framework.deviceManager.registerDeviceClass("AqaraMotionSensor", {
        configDef: deviceConfigDef.AqaraMotionSensor,
        createCallback: (config) => new AqaraMotionSensor(config)
      })


      connection = new LumiAqara()

      env.logger.debug("Searching for gateway...")
      connection.on('gateway', (gateway) =>
        env.logger.debug("Gateway discovered")

        # Gateway ready
        gateway.on('ready', () =>
          env.logger.debug('Gateway is ready')
          gateway.setPassword(@config.password)
        )

        # Gateway offline
        gateway.on('offline', () =>
          gateway = null
          env.logger.debug('Gateway is offline')
        )

        gateway.on('subdevice', (device) =>
          env.logger.info(device)
        )
      )

  class AqaraMotionSensor extends env.devices.PresenceSensor

    constructor: (@config, lastState, @board) ->
      @id = @config.id
      @name = @config.name
      @_presence = lastState?.presence?.value or false
      @_battery = lastState?.battery?.value or 0
      @_lux = lastState?.lux?.value or 0

      @addAttribute('battery', {
        description: "Battery",
        type: "number"
        displaySparkline: false
        unit: "%"
        icon:
          noText: true
          mapping: {
            'icon-battery-empty': 0
            'icon-battery-fuel-1': [0, 20]
            'icon-battery-fuel-2': [20, 40]
            'icon-battery-fuel-3': [40, 60]
            'icon-battery-fuel-4': [60, 80]
            'icon-battery-fuel-5': [80, 100]
            'icon-battery-filled': 100
          }
      })
      @['battery'] = ()-> Promise.resolve(@_battery)

      @addAttribute('lux', {
        description: "Lux",
        type: "number"
        displaySparkline: false
        unit: "lux"
      })
      @['lux'] = ()-> Promise.resolve(@_lux)

      resetPresence = ( =>
        @_setPresence(no)
      )

      # functions

      super()

    destroy: ->
      clearTimeout(@_resetPresenceTimeout)
      super()

    getPresence: -> Promise.resolve @_presence
    getBattery: -> Promise.resolve @_battery
    getLux: -> Promise.resolve @_lux


  aqara = new aqara

  return aqara
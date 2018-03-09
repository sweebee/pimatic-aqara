module.exports = (env) ->

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  events = env.require 'events'
  LumiAqara = require './lumi-aqara'

  class Board extends events.EventEmitter

    constructor: (framework, config) ->
      @config = config
      @framework = framework

      @devices = {}

      @driver = new LumiAqara()

      env.logger.debug("Searching for gateway...")
      @driver.on('gateway', (gateway) =>
        env.logger.debug("Gateway discovered")

        # Gateway ready
        gateway.on('ready', () =>
          env.logger.debug('Gateway is ready')
          gateway.setPassword(@config.password)
        )

        # Gateway offline
        gateway.on('offline', () =>
          env.logger.error('Gateway is offline')
        )

        gateway.on('subdevice', (device) =>
          env.logger.debug(device)
          @devices[device._sid] = device
          switch device.getType()
            when 'magnet'
              device.on('open', () =>
                @emit "magnet", device
              )
              device.on('close', () =>
                @emit "magnet", device
              )
            when 'motion'
              device.on('motion', () =>
                @emit "motion", device
              )
              device.on('noMotion', () =>
                @emit "motion", device
              )
            when 'leak'
              device.on('update', () =>
                @emit "leak", device
              )
            when 'sensor'
              device.on('update', () =>
                @emit "sensor", device
              )
            when 'cube'
              device.on('update', () =>
                @emit "cube", device
              )
            when 'button'
              device.on('click', () =>
                device.state = 'click'
                @emit "button", device
              )
              device.on('doubleClick', () =>
                device.state = 'doubleClick'
                @emit "button", device
              )
              device.on('longClickPress', () =>
                device.state = 'longClickPress'
                @emit "button", device
              )
              device.on('longClickRelease', () =>
                device.state = 'longClickRelease'
                @emit "button", device
              )
            when 'switch'
              device.on('click', () =>
                @emit "switch", device
              )
        )
      )

  Promise.promisifyAll(Board.prototype)

  class aqara extends env.plugins.Plugin

    init: (app, @framework, @config) =>

      @board = new Board(@framework, @config)

      @framework.deviceManager.on('discover', (eventData) =>

        @framework.deviceManager.discoverMessage(
          'pimatic-aqara', "Searching for devices"
        )
        for key, value of @board.devices
          SID = key

          newdevice = not @framework.deviceManager.devicesConfig.some (device, iterator) =>
            device.SID is SID

          if newdevice
            deviceClass = false
            switch value._type
              when 'switch'
                deviceClass = 'AqaraWirelessSwitch'
              when 'button'
                deviceClass = 'AqaraWirelessButton'
              when 'leak'
                deviceClass = 'AqaraLeakSensor'
              when 'motion'
                deviceClass = 'AqaraMotionSensor'
              when 'magnet'
                deviceClass = 'AqaraDoorSensor'

            if deviceClass
              @framework.deviceManager.discoveredDevice(
                'pimatic-aqara', "#{deviceClass}", {
                  SID: SID,
                  class: deviceClass
                }
              )
      )

      #Register devices
      deviceConfigDef = require("./device-config-schema.coffee")

      deviceClasses = [
        AqaraMotionSensor,
        AqaraDoorSensor,
        AqaraLeakSensor,
        AqaraWirelessSwitch,
        AqaraWirelessButton
      ]

      for Cl in deviceClasses
        do (Cl) =>
          @framework.deviceManager.registerDeviceClass(Cl.name, {
            configDef: deviceConfigDef[Cl.name]
            createCallback: (config,lastState) =>
              device  =  new Cl(config, lastState, @board)
              return device
          })

  class AqaraMotionSensor extends env.devices.PresenceSensor

    constructor: (@config, lastState, @board) ->
      @id = @config.id
      @name = @config.name
      @_presence = lastState?.presence?.value or false
      @_battery = lastState?.battery?.value
      @_lux = lastState?.lux?.value

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

      @rfValueEventHandler = ( (result) =>
        if result.getSid() is @config.SID
          @_setPresence(result._motion)
          clearTimeout(@_resetPresenceTimeout)
          @_resetPresenceTimeout = setTimeout(resetPresence, @config.resetTime)

          if result.getLux() != null
            @_lux = parseInt(result.getLux())
            @emit "lux", @_lux

          @_battery = result.getBatteryPercentage()
          @emit "battery", @_battery
      )

      @board.on("motion", @rfValueEventHandler)

      super()

    destroy: ->
      clearTimeout(@_resetPresenceTimeout)
      @board.removeListener "motion", @rfValueEventHandler
      super()

    getPresence: -> Promise.resolve @_presence
    getBattery: -> Promise.resolve @_battery
    getLux: -> Promise.resolve @_lux


  class AqaraDoorSensor extends env.devices.ContactSensor

    constructor: (@config, lastState, @board) ->
      @id = @config.id
      @name = @config.name
      @_contact = lastState?.contact?.value or false
      @_battery = lastState?.battery?.value

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

      @rfValueEventHandler = ( (result) =>
        if result.getSid() is @config.SID
          @_setContact(result.isOpen())
          @_battery = result.getBatteryPercentage()
          @emit "battery", @_battery
      )

      @board.on("magnet", @rfValueEventHandler)

      super()

    destroy: ->
      @board.removeListener "magnet", @rfValueEventHandler
      super()

    getContact: -> Promise.resolve @_contact
    getBattery: -> Promise.resolve @_battery

  class AqaraLeakSensor extends env.devices.Device

    constructor: (@config, lastState, @board) ->
      @id = @config.id
      @name = @config.name
      @_state = lastState?.state?.value or false
      @_battery = lastState?.battery?.value

      @attributes = {}

      @attributes.battery = {
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
      }

      @attributes.state = {
        description: "State of the remote"
        type: "boolean"
        labels: [@config.Wet, @config.Dry]
      }

      @rfValueEventHandler = ( (result) =>
        if result.getSid() is @config.SID
          @_state = result.isLeaking()
          @emit "state", @_state
          @_battery = result.getBatteryPercentage()
          @emit "battery", @_battery
      )

      @board.on("leak", @rfValueEventHandler)

      super()

    destroy: ->
      @board.removeListener "leak", @rfValueEventHandler
      super()

    getState: -> Promise.resolve @_state
    getBattery: -> Promise.resolve @_battery

  class AqaraWirelessSwitch extends env.devices.PowerSwitch

    constructor: (@config, lastState, @board) ->
      @id = @config.id
      @name = @config.name
      @_state = lastState?.state?.value or false
      @_battery = lastState?.battery?.value

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

      @rfValueEventHandler = ( (result) =>
        if result.getSid() is @config.SID
          @_setState(!@_state)
          @_battery = result.getBatteryPercentage()
          @emit "battery", @_battery
      )

      @board.on("switch", @rfValueEventHandler)

      super()

    changeStateTo: (state) ->
      @_setState(state)
      return Promise.resolve()

    destroy: ->
      @board.removeListener "switch", @rfValueEventHandler
      super()

    getSate: -> Promise.resolve @_state
    getBattery: -> Promise.resolve @_battery

  class AqaraWirelessButton extends env.devices.Device

    constructor: (@config, lastState, @board) ->
      @id = @config.id
      @name = @config.name
      @_state = lastState?.state?.value
      @_battery = lastState?.battery?.value
      @attributes = {}

      @attributes.battery = {
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
      }

      @attributes.state = {
        description: "State of the button"
        type: "string"
      }

      resetState = ( =>
        @_state = 'waiting...'
        @emit "state", @_state
      )

      @rfValueEventHandler = ( (result) =>
        if result.getSid() is @config.SID
          @_state = result.state
          @emit "state", @_state
          @_battery = result.getBatteryPercentage()
          @emit "battery", @_battery
          clearTimeout(@_resetStateTimeout)
          @_resetStateTimeout = setTimeout(resetState, @config.resetTime)
      )

      @board.on("button", @rfValueEventHandler)

      super()

    destroy: ->
      @board.removeListener "button", @rfValueEventHandler
      super()

    getState: -> Promise.resolve @_state
    getBattery: -> Promise.resolve @_battery

  aqara = new aqara

  return aqara
module.exports = (env) ->

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  events = env.require 'events'
  LumiAqara = require './lumi-aqara'

  class Board extends events.EventEmitter

    constructor: (framework, config) ->
      @config = config
      @framework = framework
      @gateway = null
      @devices = {}

      @driver = new LumiAqara()

      env.logger.debug("Searching for gateway...")
      @driver.on('gateway', (gateway) =>
        @gateway = gateway
        env.logger.info("Gateway discovered")

        # Gateway ready
        gateway.on('ready', () =>
          env.logger.debug('Gateway is ready')
          gateway.setPassword(@config.password)
        )

        # Gateway offline
        gateway.on('offline', () =>
          env.logger.warn('Gateway not reachable')
        )

        gateway.on('subdevice', (device) =>
          if not @devices[device.getSid()]?
              @emit "discovered", device
          @devices[device.getSid()] = device
          device.on('report', () =>
            env.logger.debug(device)
            @emit "report", device
          )
        )
      )

  Promise.promisifyAll(Board.prototype)

  class aqara extends env.plugins.Plugin

    init: (app, @framework, @config) =>

      @board = new Board(@framework, @config)

      @framework.deviceManager.on('discover', (eventData) =>
        if not @board.gateway
          return

        @framework.deviceManager.discoverMessage(
          'pimatic-aqara', "Searching for devices"
        )

        this.clearDiscovery()
        @discoverHandler = ( (device) =>
          this.showDiscovered(device)
        )

        @board.on("discovered", @discoverHandler)

        @board.devices = {}
        @board.gateway.getDevices()

        if @config.pairing
          @board.gateway.discover(true)
          @interval = setInterval(( =>
            @board.gateway.getDevices()
          ), 5000)

        setTimeout(( =>
          this.clearDiscovery()
        ), eventData.time)
      )

      #Register devices
      deviceConfigDef = require("./device-config-schema.coffee")

      deviceClasses = [
        AqaraMotionSensor,
        AqaraDoorSensor,
        AqaraLeakSensor,
        AqaraWirelessSwitch,
        AqaraWirelessButton,
        AqaraTemperatureSensor
      ]

      for Cl in deviceClasses
        do (Cl) =>
          @framework.deviceManager.registerDeviceClass(Cl.name, {
            configDef: deviceConfigDef[Cl.name]
            createCallback: (config,lastState) =>
              device  =  new Cl(config, lastState, @board)
              return device
          })

    showDiscovered: (device) ->

      newdevice = not @framework.deviceManager.devicesConfig.some (result, iterator) =>
        result.SID is device.getSid()

      if newdevice
        config_options = {}
        switch device.getType()
          when 'switch'
            config_options.class = 'AqaraWirelessSwitch'
          when 'button'
            config_options.class = 'AqaraWirelessButton'
          when 'leak'
            config_options.class = 'AqaraLeakSensor'
          when 'motion'
            config_options.class = 'AqaraMotionSensor'
            if not device.getLux()
              config_options.lux = false
          when 'magnet'
            config_options.class = 'AqaraDoorSensor'
          when 'sensor'
            config_options.class = 'AqaraTemperatureSensor'
            if not device.getPressure()
              config_options.pressure = false

        if config_options.class
          config_options.SID = device.getSid()
          @framework.deviceManager.discoveredDevice(
            'pimatic-aqara', "#{config_options.class}", config_options
          )

    clearDiscovery: ->
      @board.removeListener "discovered", @discoverHandler if @discoverHandler
      if @config.pairing
        @board.gateway.discover(false)
        clearInterval @interval if @interval


  class AqaraMotionSensor extends env.devices.PresenceSensor

    constructor: (@config, lastState, @board) ->
      @id = @config.id
      @name = @config.name
      @_presence = lastState?.presence?.value or false
      @_battery = lastState?.battery?.value
      if @config.lux
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

      if @config.lux
        @addAttribute('lux', {
          description: "Lux",
          type: "number"
          displaySparkline: @config.displaySparkline
          unit: "lux"
        })
        @['lux'] = ()-> Promise.resolve(@_lux)

      resetPresence = ( =>
        @_setPresence(no)
      )

      @rfValueEventHandler = ( (result) =>
        if result.getSid() is @config.SID and result.getType() is "motion"
          if(result.stateUpdated())
            unless @_presence is result.isPresent()
              @_setPresence(result.isPresent())
            clearTimeout(@_resetPresenceTimeout)
            @_resetPresenceTimeout = setTimeout(resetPresence, @config.resetTime)

          if @config.lux and result.getLux() != null
            @_lux = parseInt(result.getLux())
            @emit "lux", @_lux

          @_battery = result.getBatteryPercentage()
          @emit "battery", @_battery
      )

      @board.on("report", @rfValueEventHandler)

      super()

    destroy: ->
      clearTimeout(@_resetPresenceTimeout)
      @board.removeListener "report", @rfValueEventHandler
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
        if result.getSid() is @config.SID and result.getType() is "magnet"
          unless @_contact is result.isOpen()
            @_setContact(result.isOpen())
          @_battery = result.getBatteryPercentage()
          @emit "battery", @_battery
      )

      @board.on("report", @rfValueEventHandler)

      super()

    destroy: ->
      @board.removeListener "report", @rfValueEventHandler
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
        labels: [@config.wet, @config.dry]
      }

      @rfValueEventHandler = ( (result) =>
        if result.getSid() is @config.SID and result.getType() is "leak"
          unless @_state is result.isLeaking()
            @_state = result.isLeaking()
            @emit "state", @_state
          @_battery = result.getBatteryPercentage()
          @emit "battery", @_battery
      )

      @board.on("report", @rfValueEventHandler)

      super()

    destroy: ->
      @board.removeListener "report", @rfValueEventHandler
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
        if result.getSid() is @config.SID and result.getType() is "switch"
          if result.stateUpdated()
            @_setState(!@_state)
          @_battery = result.getBatteryPercentage()
          @emit "battery", @_battery
      )

      @board.on("report", @rfValueEventHandler)

      super()

    changeStateTo: (state) ->
      @_setState(state)
      return Promise.resolve()

    destroy: ->
      @board.removeListener "report", @rfValueEventHandler
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
        if result.getSid() is @config.SID and result.getType() is "button"
          if result.stateUpdated()
            @_state = result.state
            @emit "state", @_state
            clearTimeout(@_resetStateTimeout)
          @_battery = result.getBatteryPercentage()
          @emit "battery", @_battery
          @_resetStateTimeout = setTimeout(resetState, @config.resetTime)
      )

      @board.on("report", @rfValueEventHandler)

      super()

    destroy: ->
      @board.removeListener "report", @rfValueEventHandler
      super()

    getState: -> Promise.resolve @_state
    getBattery: -> Promise.resolve @_battery

  class AqaraTemperatureSensor extends env.devices.Device

    constructor: (@config, lastState, @board) ->
      @id = @config.id
      @name = @config.name
      @_temperature = lastState?.temperature?.value
      @_humidity = lastState?.humidity?.value
      if @config.pressure
        @_pressure = lastState?.pressure?.value
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

      @attributes.temperature = {
        description: "the measured temperature"
        type: "number"
        unit: "°C"
        acronym: 'T'
      }

      @attributes.humidity = {
        description: "the measured humidity"
        type: "number"
        unit: '%'
        acronym: 'H'
      }

      if @config.pressure
        @attributes.pressure = {
          description: "the measured pressure"
          type: "number"
          unit: 'kPa'
          acronym: 'P'
        }

      @rfValueEventHandler = ( (result) =>
        if result.getSid() is @config.SID
          @_temperature = parseFloat(result.getTemperature())
          @emit "temperature", @_temperature
          @_humidity = parseFloat(result.getHumidity())
          @emit "humidity", @_humidity
          if @config.pressure
            @_pressure = parseFloat(result.getPressure())
            @emit "pressure", @_pressure
          @_battery = result.getBatteryPercentage()
          @emit "battery", @_battery
      )

      @board.on("sensor", @rfValueEventHandler)

      super()

    destroy: ->
      @board.removeListener "sensor", @rfValueEventHandler
      super()

    getTemperature: -> Promise.resolve @_temperature
    getHumidity: -> Promise.resolve @_humidity
    getPressure: -> Promise.resolve @_pressure
    getBattery: -> Promise.resolve @_battery

  aqara = new aqara

  return aqara

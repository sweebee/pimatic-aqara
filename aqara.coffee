module.exports = (env) ->

  Promise = env.require 'bluebird'
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
          env.logger.info('Gateway is ready')
          gateway.setPassword(@config.password)
        )

        # Gateway offline
        gateway.on('offline', () =>
          env.logger.warn('Gateway not reachable')
        )

        # Receiving subdevices
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

        # Listen to discovered devices
        @board.on("discovered", @discoverHandler)

        @board.devices = {}
        @board.gateway.getDevices()

        # If pairing is enabled, send it to the gateway
        if @config.pairing
          @board.gateway.discover(true)
          @interval = setInterval(( =>
            @board.gateway.getDevices()
          ), 5000)

        # Disable discovering after 20s
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
        AqaraTemperatureSensor,
        AqaraMagicCube
      ]

      for Cl in deviceClasses
        do (Cl) =>
          @framework.deviceManager.registerDeviceClass(Cl.name, {
            configDef: deviceConfigDef[Cl.name]
            createCallback: (config, lastState) =>
              device  =  new Cl(config, lastState, @board, @config)
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
          when 'temperature'
            config_options.class = 'AqaraTemperatureSensor'
            if not device.getPressure()
              config_options.pressure = false
          when 'cube'
            config_options.class = 'AqaraMagicCube'

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

    constructor: (@config, lastState, @board, @baseConfig) ->
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

      # If lux is enabled, add it
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

      # Report handler
      @reportHandler = ( (result) =>

        if result.getSid() is @config.SID and result.getType() is "motion"

          # Update presence
          if(result.stateUpdated())
            unless @_presence is result.isPresent()
              @_setPresence(result.isPresent())
            if @config.autoReset
              clearTimeout(@_resetPresenceTimeout)
              @_resetPresenceTimeout = setTimeout(resetPresence, @config.resetTime)

          # Update lux value
          if @config.lux and result.getLux() != null
            @_lux = parseInt(result.getLux())
            @emit "lux", @_lux

          # Update battery value
          @_battery = @_battery = result.getBatteryPercentage(@baseConfig.batteryMin, @baseConfig.batteryMax)
          @emit "battery", @_battery

      )

      # Listen for device reports
      @board.on("report", @reportHandler)

      super()

    destroy: ->
      clearTimeout(@_resetPresenceTimeout)
      @board.removeListener "report", @reportHandler
      super()

    getPresence: -> Promise.resolve @_presence
    getBattery: -> Promise.resolve @_battery
    getLux: -> Promise.resolve @_lux

  class AqaraDoorSensor extends env.devices.ContactSensor

    constructor: (@config, lastState, @board, @baseConfig) ->
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

      # Report handler
      @reportHandler = ( (result) =>

        if result.getSid() is @config.SID and result.getType() is "magnet"

          # Update the door/window state
          if result.stateUpdated()
            unless @_contact is result.isOpen()
              @_setContact(result.isOpen())

          # Update the battery value
          @_battery = result.getBatteryPercentage(@baseConfig.batteryMin, @baseConfig.batteryMax)
          @emit "battery", @_battery

      )

      # Listen for device reports
      @board.on("report", @reportHandler)

      super()

    destroy: ->
      @board.removeListener "report", @reportHandler
      super()

    getContact: -> Promise.resolve @_contact
    getBattery: -> Promise.resolve @_battery

  class AqaraLeakSensor extends env.devices.Device

    constructor: (@config, lastState, @board, @baseConfig) ->
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
        description: "State of the leak sensor"
        type: "boolean"
        labels: [@config.wet, @config.dry]
      }

      # Report handler
      @reportHandler = ( (result) =>

        if result.getSid() is @config.SID and result.getType() is "leak"

          # Check the leak status
          if result.stateUpdated()
            unless @_state is result.isLeaking()
              @_state = result.isLeaking()
              @emit "state", @_state

          # Update the battery value
          @_battery = @_battery = result.getBatteryPercentage(@baseConfig.batteryMin, @baseConfig.batteryMax)
          @emit "battery", @_battery

      )

      # Listen for device reports
      @board.on("report", @reportHandler)

      super()

    destroy: ->
      @board.removeListener "report", @reportHandler
      super()

    getState: -> Promise.resolve @_state
    getBattery: -> Promise.resolve @_battery

  class AqaraWirelessSwitch extends env.devices.PowerSwitch

    constructor: (@config, lastState, @board, @baseConfig) ->
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

      # Report handler
      @reportHandler = ( (result) =>

        if result.getSid() is @config.SID and result.getType() is "switch"

          # Check if clicked
          if result.stateUpdated()
            @_setState(!@_state)

          # Update the battery value
          @_battery = @_battery = result.getBatteryPercentage(@baseConfig.batteryMin, @baseConfig.batteryMax)
          @emit "battery", @_battery

      )

      # Listen for device reports
      @board.on("report", @reportHandler)

      super()

    changeStateTo: (state) ->
      @_setState(state)
      return Promise.resolve()

    destroy: ->
      @board.removeListener "report", @reportHandler
      super()

    getSate: -> Promise.resolve @_state
    getBattery: -> Promise.resolve @_battery

  class AqaraWirelessButton extends env.devices.Device

    constructor: (@config, lastState, @board, @baseConfig) ->
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

      # Reset the state
      resetState = ( =>
        @_state = @config.waitingState
        @emit "state", @_state
      )

      # Report handler
      @reportHandler = ( (result) =>

        if result.getSid() is @config.SID and result.getType() is "button"

          # Check if the button is pressed
          if result.stateUpdated()
            @_state = result.getState()
            @emit "state", @_state
            clearTimeout(@_resetStateTimeout)
            @_resetStateTimeout = setTimeout(resetState, @config.resetTime)

          # Update the battery value
          @_battery = @_battery = result.getBatteryPercentage(@baseConfig.batteryMin, @baseConfig.batteryMax)
          @emit "battery", @_battery

      )

      # Listen for device reports
      @board.on("report", @reportHandler)

      super()

    destroy: ->
      @board.removeListener "report", @reportHandler
      super()

    getState: -> Promise.resolve @_state
    getBattery: -> Promise.resolve @_battery

  class AqaraTemperatureSensor extends env.devices.Device

    constructor: (@config, lastState, @board, @baseConfig) ->
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

      # Report handler
      @reportHandler = ( (result) =>

        if result.getSid() is @config.SID and result.getType() == 'temperature'

          # Update the temperature value
          if result.getTemperature() > -20 and result.getTemperature() < 60
            @_temperature = parseFloat(result.getTemperature())
            @emit "temperature", @_temperature

          # Update the humidity value
          if result.getHumidity() > 0 and result.getHumidity() <= 100
            @_humidity = parseFloat(result.getHumidity())
            @emit "humidity", @_humidity

          # Update the pressure value
          if @config.pressure and result.getPressure() != null
            @_pressure = parseFloat(result.getPressure())
            @emit "pressure", @_pressure

          # Update the battery value
          @_battery = @_battery = result.getBatteryPercentage(@baseConfig.batteryMin, @baseConfig.batteryMax)
          @emit "battery", @_battery

      )

      # Listen for device reports
      @board.on("report", @reportHandler)

      super()

    destroy: ->
      @board.removeListener "report", @reportHandler
      super()

    getTemperature: -> Promise.resolve @_temperature
    getHumidity: -> Promise.resolve @_humidity
    getPressure: -> Promise.resolve @_pressure
    getBattery: -> Promise.resolve @_battery


  class AqaraMagicCube extends env.devices.Device

    constructor: (@config, lastState, @board, @baseConfig) ->
      @id = @config.id
      @name = @config.name
      @_state = lastState?.state?.value
      @_rotation = lastState?.rotation?.value or 0
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

      @attributes.rotation = {
        description: "Rotation of the cube"
        type: "number"
        displaySparkline: false
      }

      @attributes.state = {
        description: "State of the cube"
        type: "string"
      }

      # Report handler
      @reportHandler = ( (result) =>

        if result.getSid() is @config.SID and result.getType() is "cube"

          # Check if something happened to the cube
          if result.stateUpdated()
            @_state = result.getState()
            @emit "state", @_state
            @_rotation = result.getRotation()
            @emit "rotation", @_rotation

          # Update the battery value
          @_battery = @_battery = result.getBatteryPercentage(@baseConfig.batteryMin, @baseConfig.batteryMax)
          @emit "battery", @_battery

      )

      # Listen for device reports
      @board.on("report", @reportHandler)

      super()

    destroy: ->
      @board.removeListener "report", @reportHandler
      super()

    getState: -> Promise.resolve @_state
    getRotation: -> Promise.resolve @_rotation
    getBattery: -> Promise.resolve @_battery

  aqara = new aqara

  return aqara

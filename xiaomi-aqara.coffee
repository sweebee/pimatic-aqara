module.exports = (env) ->

  Promise = env.require 'bluebird'
  assert = env.require 'cassert'
  Aqara = require './aqara'

  class xiaomiAqara extends env.plugins.Plugin

    init: (app, @framework, @config) =>
      aqara = new Aqara()

      env.logger.debug("Searching for gateway...")
      aqara.on('gateway', (gateway) =>
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

  xiaomiAqara = new xiaomiAqara

  return xiaomiAqara
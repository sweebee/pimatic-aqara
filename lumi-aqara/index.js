'use strict';

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var dgram = require('dgram');
var os = require('os');
var events = require('events');

var _require = require('./constants'),
    MULTICAST_ADDRESS = _require.MULTICAST_ADDRESS,
    DISCOVERY_PORT = _require.DISCOVERY_PORT,
    SERVER_PORT = _require.SERVER_PORT;

var Gateway = require('./lib/gateway');

var Aqara = function (_events$EventEmitter) {
  _inherits(Aqara, _events$EventEmitter);

  function Aqara() {
    _classCallCheck(this, Aqara);

    var _this = _possibleConstructorReturn(this, (Aqara.__proto__ || Object.getPrototypeOf(Aqara)).call(this));

    _this._gateways = new Map();

    _this._serverSocket = dgram.createSocket('udp4');
    _this._serverSocket.on('listening', function () {
      var networkIfaces = os.networkInterfaces();
      for (var ifaceName in networkIfaces) {
        var networkIface = networkIfaces[ifaceName];

        var _iteratorNormalCompletion = true;
        var _didIteratorError = false;
        var _iteratorError = undefined;

        try {
          var i = 0;
          for (var _iterator = networkIface[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
            var connection = _step.value;
            if (connection.family === 'IPv4') {
              if(i == 0){
                _this._serverSocket.addMembership(MULTICAST_ADDRESS, connection.address);
                i++;
              }
            }
          }
        } catch (err) {
          _didIteratorError = true;
          _iteratorError = err;
        } finally {
          try {
            if (!_iteratorNormalCompletion && _iterator.return) {
              _iterator.return();
            }
          } finally {
            if (_didIteratorError) {
              throw _iteratorError;
            }
          }
        }
      }

      _this._triggerWhois();
    });

    _this._serverSocket.on('message', _this._handleMessage.bind(_this));

    _this._serverSocket.bind(SERVER_PORT, '0.0.0.0');
    return _this;
  }

  _createClass(Aqara, [{
    key: '_triggerWhois',
    value: function _triggerWhois() {
      var payload = '{"cmd": "whois"}';
      this._serverSocket.send(payload, 0, payload.length, DISCOVERY_PORT, MULTICAST_ADDRESS);
    }
  }, {
    key: '_handleMessage',
    value: function _handleMessage(msg) {
      var _this2 = this;

      var parsed = JSON.parse(msg.toString());

      var handled = false;

      switch (parsed.cmd) {
        case 'heartbeat':
          if (!this._gateways.has(parsed.sid)) {
            handled = true;
            this._triggerWhois();
          }
          break;
        case 'iam':
          handled = true;
          if (this._gateways.has(parsed.sid)) break;
          var gateway = new Gateway({
            ip: parsed.ip,
            sid: parsed.sid,
            sendUnicast: function sendUnicast(payload) {
              return _this2._serverSocket.send(payload, 0, payload.length, SERVER_PORT, parsed.ip);
            }
          });
          gateway.on('offline', function () {
            return _this2._gateways.delete(parsed.sid);
          });
          this._gateways.set(parsed.sid, gateway);
          this.emit('gateway', gateway);
          break;
      }

      if (!handled) {


        // propagate to gateways
        var _iteratorNormalCompletion2 = true;
        var _didIteratorError2 = false;
        var _iteratorError2 = undefined;

        try {
          for (var _iterator2 = this._gateways.values()[Symbol.iterator](), _step2; !(_iteratorNormalCompletion2 = (_step2 = _iterator2.next()).done); _iteratorNormalCompletion2 = true) {
            var _gateway = _step2.value;

            handled = _gateway._handleMessage(parsed);
            if (handled) break;
          }
        } catch (err) {
          _didIteratorError2 = true;
          _iteratorError2 = err;
        } finally {
          try {
            if (!_iteratorNormalCompletion2 && _iterator2.return) {
              _iterator2.return();
            }
          } finally {
            if (_didIteratorError2) {
              throw _iteratorError2;
            }
          }
        }
      }

      if (!handled) console.log(`not handled: ${JSON.stringify(parsed)}`);
    }
  }]);

  return Aqara;
}(events.EventEmitter);

module.exports = Aqara;

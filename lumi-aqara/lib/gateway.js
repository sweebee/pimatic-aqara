'use strict';

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var crypto = require('crypto');
var events = require('events');

var _require = require('../constants'),
    AQARA_IV = _require.AQARA_IV,
    GATEWAY_HEARTBEAT_INTERVAL_MS = _require.GATEWAY_HEARTBEAT_INTERVAL_MS,
    GATEWAY_HEARTBEAT_OFFLINE_RATIO = _require.GATEWAY_HEARTBEAT_OFFLINE_RATIO;

var Subdevice = require('./subdevice');

var Gateway = function (_events$EventEmitter) {
  _inherits(Gateway, _events$EventEmitter);

  function Gateway(opts) {
    _classCallCheck(this, Gateway);

    var _this = _possibleConstructorReturn(this, (Gateway.__proto__ || Object.getPrototypeOf(Gateway)).call(this));

    _this._ip = opts.ip;
    _this._sid = opts.sid;
    _this._sendUnicast = opts.sendUnicast;

    _this._heartbeatWatchdog = null;
    _this._rearmWatchdog();

    _this._color = { r: 0, g: 0, b: 0 };

    _this._subdevices = new Map();

    var payload = '{"cmd": "get_id_list"}';
    _this._sendUnicast(payload);
    return _this;
  }

  _createClass(Gateway, [{
    key: '_rearmWatchdog',
    value: function _rearmWatchdog() {
      var _this2 = this;

      if (this._heartbeatWatchdog) clearTimeout(this._heartbeatWatchdog);
      this._heartbeatWatchdog = setTimeout(function () {
        _this2.emit('offline');
      }, GATEWAY_HEARTBEAT_INTERVAL_MS * GATEWAY_HEARTBEAT_OFFLINE_RATIO);
    }
  }, {
    key: '_handleMessage',
    value: function _handleMessage(msg) {
      var sid = void 0;
      var type = void 0;
      var state = void 0;
      switch (msg.cmd) {
        case 'get_id_list_ack':
          this._refreshKey(msg.token);

          var payload = `{"cmd": "read", "sid": "${this._sid}"}`;
          this._sendUnicast(payload);
          // read subdevices
          var _iteratorNormalCompletion = true;
          var _didIteratorError = false;
          var _iteratorError = undefined;

          try {
            for (var _iterator = JSON.parse(msg.data)[Symbol.iterator](), _step; !(_iteratorNormalCompletion = (_step = _iterator.next()).done); _iteratorNormalCompletion = true) {
              var _sid = _step.value;

              var _payload = `{"cmd": "read", "sid": "${_sid}"}`;
              this._sendUnicast(_payload);
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

          break;
        case 'read_ack':
          sid = msg.sid;
          type = msg.model;
          state = JSON.parse(msg.data);

          if (sid === this._sid) {
            // self
            this._handleState(state);
            if(! this._ready) {
                this._ready = true;
                this.emit('ready');
            }
          } else {
            var subdevice = void 0;
            switch (type) {
              case 'magnet':
              case 'sensor_magnet.aq2':
                subdevice = new Subdevice({ sid, type: 'magnet' });
                break;
              case '86sw1':
                subdevice = new Subdevice({ sid, type: 'switch' });
                break;
              case 'switch':
              case 'sensor_switch.aq2':
                subdevice = new Subdevice({ sid, type: 'button' });
                break;
              case 'motion':
              case 'sensor_motion.aq2':
                subdevice = new Subdevice({ sid, type: 'motion' });
                break;
              case 'sensor_ht':
              case 'weather.v1':
                subdevice = new Subdevice({ sid, type: 'temperature' });
                break;
              case 'sensor_wleak.aq1':
                subdevice = new Subdevice({ sid, type: 'leak' });
                break;
              case 'cube':
                subdevice = new Subdevice({ sid, type: 'cube' });
                break;
              default:
                return false;
            }

            if (subdevice) {
              this._subdevices.set(msg.sid, subdevice);
              subdevice._handleState(state);
              this.emit('subdevice', subdevice);
            }
          }
          break;
        case 'heartbeat':
          if (msg.sid === this._sid) {
            this._refreshKey(msg.token);
            this._rearmWatchdog();
          } // self
          else {
              var _subdevice = this._subdevices.get(msg.sid);
              if (_subdevice) {
                  this.emit('heartbeat', msg);
                  _subdevice._handleState(state);
              } else {
                  // console.log('did not manage to find device, or device not yet supported')
              }
          }
          break;
        case 'report':
          state = JSON.parse(msg.data);
          if (msg.sid === this._sid) {
            this._handleState(state);
          } // self
          else {
              var _subdevice = this._subdevices.get(msg.sid);
              if (_subdevice) {
                _subdevice._handleState(state);
              } else {
                // console.log('did not manage to find device, or device not yet supported')
              }
            }
          break;
      }

      return true;
    }
  }, {
    key: '_handleState',
    value: function _handleState(state) {
      var buf = Buffer.alloc(4);
      buf.writeUInt32BE(state.rgb, 0);
      this._color.r = buf.readUInt8(1);
      this._color.g = buf.readUInt8(2);
      this._color.b = buf.readUInt8(3);
      this._intensity = buf.readUInt8(0); // 0-100

      this.emit('lightState', { color: this._color, intensity: this._intensity });
    }
  }, {
    key: '_refreshKey',
    value: function _refreshKey(token) {
      if (token) this._token = token;
      if (!this._password || !this._token) return;

      var cipher = crypto.createCipheriv('aes-128-cbc', this._password, AQARA_IV);
      this._key = cipher.update(this._token, 'ascii', 'hex');
      cipher.final('hex'); // useless
    }
  }, {
    key: '_writeColor',
    value: function _writeColor() {
      var buf = Buffer.alloc(4);
      buf.writeUInt8(this._intensity, 0);
      buf.writeUInt8(this._color.r, 1);
      buf.writeUInt8(this._color.g, 2);
      buf.writeUInt8(this._color.b, 3);

      var value = buf.readUInt32BE(0);

      var payload = `{"cmd": "write", "model": "gateway", "sid": "${this._sid}", "short_id": 0, "data": "{\\"rgb\\":${value}, \\"key\\": \\"${this._key}\\"}"}`;
      this._sendUnicast(payload);
    }
  }, {
      key: 'discover',
      value: function discover(on) {
          if (!this._ready) return;
          var state;
          if(on){
            state = "yes";
          } else {
            state = "no";
          }

          var payload = '{"cmd":"write","model":"gateway","sid":"'+ this._sid +'","short_id":0,"data":"{\"join_permission\":"' + state + '\", \"key\": \"' + this._key + '\"}" }';
          this._sendUnicast(payload);
      }
  }, {
      key: 'getDevices',
      value: function discover() {
          if (!this._ready) return;
          var payload = '{"cmd": "get_id_list"}';
          this._sendUnicast(payload);
      }
  },{
      key: 'read',
      value: function read(sid) {
          if (!this._ready) return;
          var payload = '{"cmd":"read","sid":"' + sid + '"}';
          this._sendUnicast(payload);
      }
  }, {
    key: 'setPassword',
    value: function setPassword(password) {
      if(this._password){
        return;
      }
      this._password = password;
      this._refreshKey();
    }
  }, {
    key: 'setColor',
    value: function setColor(color) {
      if (!this._ready) return;

      this._color = color;
      this._writeColor();
    }
  }, {
    key: 'setIntensity',
    value: function setIntensity(intensity) {
      if (!this._ready) return;

      this._intensity = intensity;
      this._writeColor();
    }
  }, {
    key: 'ip',
    get: function get() {
      return this._ip;
    }
  }, {
    key: 'sid',
    get: function get() {
      return this._sid;
    }
  }, {
    key: 'ready',
    get: function get() {
      return this._ready;
    }
  }, {
    key: 'password',
    get: function get() {
      return this._password;
    }
  }, {
    key: 'color',
    get: function get() {
      return this._color;
    }
  }, {
    key: 'intensity',
    get: function get() {
      return this._intensity;
    }
  }]);

  return Gateway;
}(events.EventEmitter);

module.exports = Gateway;
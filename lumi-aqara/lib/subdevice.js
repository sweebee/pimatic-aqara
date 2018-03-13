'use strict';

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var events = require('events');

var _require = require('../constants'),
    SUBDEVICE_MIN_VOLT = _require.SUBDEVICE_MIN_VOLT,
    SUBDEVICE_MAX_VOLT = _require.SUBDEVICE_MAX_VOLT;

var Subdevice = function (_events$EventEmitter) {
  _inherits(Subdevice, _events$EventEmitter);

  function Subdevice(opts) {
    _classCallCheck(this, Subdevice);

    var _this = _possibleConstructorReturn(this, (Subdevice.__proto__ || Object.getPrototypeOf(Subdevice)).call(this));

    _this._sid = opts.sid;
    _this._type = opts.type;

    _this._voltage = null;
    return _this;
  }

  _createClass(Subdevice, [{
    key: '_handleState',
    value: function _handleState(state) {
      if (typeof state.voltage !== 'undefined') this._voltage = state.voltage;
    }
  }, {
    key: 'getSid',
    value: function getSid() {
      return this._sid;
    }
  }, {
    key: 'getType',
    value: function getType() {
      return this._type;
    }
  }, {
    key: 'getBatteryVoltage',
    value: function getBatteryVoltage() {
      return this._voltage;
    }
  }, {
    key: 'getBatteryPercentage',
    value: function getBatteryPercentage() {
      var perc = 100 - Math.round((SUBDEVICE_MAX_VOLT - this._voltage) / (SUBDEVICE_MAX_VOLT - SUBDEVICE_MIN_VOLT) * 100);
      return Math.min(Math.max(perc, 0), 100);
    }
  }]);

  return Subdevice;
}(events.EventEmitter);

module.exports = Subdevice;
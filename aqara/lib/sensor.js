'use strict';

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _get = function get(object, property, receiver) { if (object === null) object = Function.prototype; var desc = Object.getOwnPropertyDescriptor(object, property); if (desc === undefined) { var parent = Object.getPrototypeOf(object); if (parent === null) { return undefined; } else { return get(parent, property, receiver); } } else if ("value" in desc) { return desc.value; } else { var getter = desc.get; if (getter === undefined) { return undefined; } return getter.call(receiver); } };

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var Subdevice = require('./subdevice');

var Sensor = function (_Subdevice) {
  _inherits(Sensor, _Subdevice);

  function Sensor(opts) {
    _classCallCheck(this, Sensor);

    var _this = _possibleConstructorReturn(this, (Sensor.__proto__ || Object.getPrototypeOf(Sensor)).call(this, { sid: opts.sid, type: 'sensor' }));

    _this._temperature = null;
    _this._humidity = null;
    _this._pressure = null;
    return _this;
  }

  _createClass(Sensor, [{
    key: '_handleState',
    value: function _handleState(state) {
      var _this2 = this;

      _get(Sensor.prototype.__proto__ || Object.getPrototypeOf(Sensor.prototype), '_handleState', this).call(this, state);

      // all fields come at once at first but one-by-one later
      if (state.temperature) {
        this._temperature = state.temperature / 100;
      }
      if (state.humidity) {
        this._humidity = state.humidity / 100;
      }
      if (state.pressure) {
        this._pressure = state.pressure / 1000;
      }

      if (this._timeout) {
        clearTimeout(this._timeout);
      }

      this._timeout = setTimeout(function () {
        _this2.emit('update');
        _this2._timeout = null;
      }, 25);
    }
  }, {
    key: 'getTemperature',
    value: function getTemperature() {
      return this._temperature;
    }
  }, {
    key: 'getHumidity',
    value: function getHumidity() {
      return this._humidity;
    }
  }, {
    key: 'getPressure',
    value: function getPressure() {
      return this._pressure;
    }
  }]);

  return Sensor;
}(Subdevice);

module.exports = Sensor;
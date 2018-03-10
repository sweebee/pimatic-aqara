'use strict';

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _get = function get(object, property, receiver) { if (object === null) object = Function.prototype; var desc = Object.getOwnPropertyDescriptor(object, property); if (desc === undefined) { var parent = Object.getPrototypeOf(object); if (parent === null) { return undefined; } else { return get(parent, property, receiver); } } else if ("value" in desc) { return desc.value; } else { var getter = desc.get; if (getter === undefined) { return undefined; } return getter.call(receiver); } };

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var Subdevice = require('./subdevice');

var Leak = function (_Subdevice) {
  _inherits(Leak, _Subdevice);

  function Leak(opts) {
    _classCallCheck(this, Leak);

    var _this = _possibleConstructorReturn(this, (Leak.__proto__ || Object.getPrototypeOf(Leak)).call(this, { sid: opts.sid, type: 'leak' }));

    _this._leaking = null;
    return _this;
  }

  _createClass(Leak, [{
    key: '_handleState',
    value: function _handleState(state) {
      _get(Leak.prototype.__proto__ || Object.getPrototypeOf(Leak.prototype), '_handleState', this).call(this, state);

      if (typeof state.status === 'undefined'){
        this.emit('battery');
      } else {

          // possible state values are: leak, no_leak, iam
          // iam is emitted when the sensor is squeezed and should not affect the state
          if (state.status === 'leak') this._leaking = true; else if (state.status === 'no_leak') this._leaking = false;

          this.emit('update');
      }
    }
  }, {
    key: 'isLeaking',
    value: function isLeaking() {
      return this._leaking;
    }
  }]);

  return Leak;
}(Subdevice);

module.exports = Leak;
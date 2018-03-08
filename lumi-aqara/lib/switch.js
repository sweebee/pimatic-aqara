'use strict';

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

var _get = function get(object, property, receiver) { if (object === null) object = Function.prototype; var desc = Object.getOwnPropertyDescriptor(object, property); if (desc === undefined) { var parent = Object.getPrototypeOf(object); if (parent === null) { return undefined; } else { return get(parent, property, receiver); } } else if ("value" in desc) { return desc.value; } else { var getter = desc.get; if (getter === undefined) { return undefined; } return getter.call(receiver); } };

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function _possibleConstructorReturn(self, call) { if (!self) { throw new ReferenceError("this hasn't been initialised - super() hasn't been called"); } return call && (typeof call === "object" || typeof call === "function") ? call : self; }

function _inherits(subClass, superClass) { if (typeof superClass !== "function" && superClass !== null) { throw new TypeError("Super expression must either be null or a function, not " + typeof superClass); } subClass.prototype = Object.create(superClass && superClass.prototype, { constructor: { value: subClass, enumerable: false, writable: true, configurable: true } }); if (superClass) Object.setPrototypeOf ? Object.setPrototypeOf(subClass, superClass) : subClass.__proto__ = superClass; }

var Subdevice = require('./subdevice');

var Switch = function (_Subdevice) {
  _inherits(Switch, _Subdevice);

  function Switch(opts) {
    _classCallCheck(this, Switch);

    return _possibleConstructorReturn(this, (Switch.__proto__ || Object.getPrototypeOf(Switch)).call(this, { sid: opts.sid, type: 'switch' }));
  }

  _createClass(Switch, [{
    key: '_handleState',
    value: function _handleState(state) {
      _get(Switch.prototype.__proto__ || Object.getPrototypeOf(Switch.prototype), '_handleState', this).call(this, state);

      if (typeof state.status === 'undefined' && typeof state.channel_0 === 'undefined') return; // might be no_close

      if(typeof state.status === 'undefined'){
        state.status = state.channel_0;
      }

      switch (state.status) {
        case 'click':
          this.emit('click');
          break;
        case 'double_click':
          this.emit('doubleClick');
          break;
        case 'long_click_press':
          this.emit('longClickPress');
          break;
        case 'long_click_release':
          this.emit('longClickRelease');
          break;
      }
    }
  }]);

  return Switch;
}(Subdevice);

module.exports = Switch;
import 'package:flutter/material.dart';

enum PanelShape { rectangle, rounded }

enum DockType { inside, outside }

enum PanelState { open, closed }

class FloatBoxPanel extends StatefulWidget {
  final double positionTop;
  final double positionLeft;
  final Color borderColor;
  final double borderWidth;
  final double size;
  final double iconSize;
  final IconData panelIcon;
  final BorderRadius borderRadius;
  final Color backgroundColor;
  final Color contentColor;
  final PanelShape panelShape;
  final PanelState panelState;
  final double panelOpenOffset;
  final int panelAnimDuration;
  final Curve panelAnimCurve;
  final DockType dockType;
  final double dockOffset;
  final int dockAnimDuration;
  final Curve dockAnimCurve;
  final List<IconData> buttons;
  final Function(int) onPressed;
  final Widget widget;
  final Widget bubble;
  final bool cancelable;
  final Function onCloseCallBack;

  FloatBoxPanel(
      {this.buttons,
      this.positionTop,
      this.positionLeft,
      this.borderColor,
      this.borderWidth,
      this.iconSize,
      this.panelIcon,
      this.size,
      this.borderRadius,
      this.panelState,
      this.panelOpenOffset,
      this.panelAnimDuration,
      this.panelAnimCurve,
      this.backgroundColor,
      this.contentColor,
      this.panelShape,
      this.dockType,
      this.dockOffset,
      this.dockAnimCurve,
      this.dockAnimDuration,
      this.onPressed, this.widget, this.bubble, this.cancelable, this.onCloseCallBack});

  @override
  _FloatBoxState createState() => _FloatBoxState();
}

class _FloatBoxState extends State<FloatBoxPanel> with TickerProviderStateMixin {
  // Required to set the default state to closed when the widget gets initialized;
  PanelState _panelState = PanelState.closed;

  // Default positions for the panel;
  double _positionTop ;
  double _positionLeft ;

  // ** PanOffset ** is used to calculate the distance from the edge of the panel
  // to the cursor, to calculate the position when being dragged;
  double _panOffsetTop = 0.0;
  double _panOffsetLeft = 0.0;

  // This is the animation duration for the panel movement, it's required to
  // dynamically change the speed depending on what the panel is being used for.
  // e.g: When panel opened or closed, the position should change in a different
  // speed than when the panel is being dragged;
  int _movementSpeed = 0;
  bool _dragging = false;
  bool _closed = false;

  AnimationController _pulseController;
  Animation<double> _pulse;

  @override
  void initState() {
    _pulseController = AnimationController(vsync: this , duration: Duration(milliseconds: 400));
    var _curvedPulse = CurvedAnimation(parent: _pulseController, curve: Curves.bounceIn , reverseCurve: Curves.bounceIn);
    _pulse = Tween<double>(begin:0.8 , end:1.0).animate(_curvedPulse);
    _pulseController.repeat(reverse: true);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if(_closed)
      return Container();
    if(_positionTop == null || _positionLeft == null){
      _positionTop = widget.positionTop ?? MediaQuery.of(context).size.height/2;
      _positionLeft = widget.positionLeft ?? MediaQuery.of(context).size.width - ((widget.size??70.0)/3 * 2);
    }
    // Width and height of page is required for the dragging the panel;
    double _pageWidth = MediaQuery.of(context).size.width;
    double _pageHeight = MediaQuery.of(context).size.height;

    // All Buttons;
    List<IconData> _buttons = widget.buttons;

    // Dock offset creates the boundary for the page depending on the DockType;
    double _dockOffset = widget.dockOffset ?? 20.0;

    // Widget size if the width of the panel;
    double _widgetSize = widget.size ?? 70.0;

    // **** METHODS ****

    // Dock boundary is calculated according to the dock offset and dock type.
    double _dockBoundary() {
      if (widget.dockType != null && widget.dockType == DockType.inside) {
        // If it's an 'inside' type dock, dock offset will remain the same;
        return _dockOffset;
      } else {
        // If it's an 'outside' type dock, dock offset will be inverted, hence
        // negative value;
        return -_dockOffset;
      }
    }

    // If panel shape is set to rectangle, the border radius will be set to custom
    // border radius property of the WIDGET, else it will be set to the size of
    // widget to make all corners rounded.
    BorderRadius _borderRadius() {
      if (widget.panelShape != null &&
          widget.panelShape == PanelShape.rectangle) {
        // If panel shape is 'rectangle', border radius can be set to custom or 0;
        return widget.borderRadius ?? BorderRadius.circular(0);
      } else {
        // If panel shape is 'rounded', border radius will be the size of widget
        // to make it rounded;
        return BorderRadius.circular(_widgetSize);
      }
    }

    // Total buttons are required to calculate the height of the panel;
    double _totalButtons() {
      if (widget.buttons == null) {
        return 0;
      } else {
        return widget.buttons.length.toDouble();
      }
    }

    // Height of the panel according to the panel state;
    double _panelHeight() {
      if (_panelState == PanelState.open) {
        // Panel height will be in multiple of total buttons, I have added "1"
        // digit height for each button to fix the overflow issue. Don't know
        // what's causing this, but adding "1" fixed the problem for now.
        return (_widgetSize + (_widgetSize + 1) * _totalButtons()) +
            (widget.borderWidth ?? 0);
      } else {
        return _widgetSize + (widget.borderWidth ?? 0) * 2;
      }
    }

    // Panel top needs to be recalculated while opening the panel, to make sure
    // the height doesn't exceed the bottom of the page;
    void _calcPanelTop() {
      if (_positionTop + _panelHeight() > _pageHeight + _dockBoundary()) {
        _positionTop = _pageHeight - _panelHeight() + _dockBoundary();
      }
    }

    // Dock Left position when open;
    double _openDockLeft() {
      if (_positionLeft < (_pageWidth / 2)) {
        // If panel is docked to the left;
        return widget.panelOpenOffset ?? 30.0;
      } else {
        // If panel is docked to the right;
        return ((_pageWidth - _widgetSize)) - (widget.panelOpenOffset ?? 30.0);
      }
    }

    // Panel border is only enabled if the border width is greater than 0;
    Border _panelBorder() {
      if (widget.borderWidth != null && widget.borderWidth > 0) {
        return Border.all(
          color: widget.borderColor ?? Color(0xFF333333),
          width: widget.borderWidth ?? 0.0,
        );
      } else {
        return null;
      }
    }

    // Force dock will dock the panel to it's nearest edge of the screen;
    void _forceDock() {
      // Calculate the center of the panel;
      double center = _positionLeft + (_widgetSize / 2);

      // Set movement speed to the custom duration property or '300' default;
      _movementSpeed = widget.dockAnimDuration ?? 300;

      // Check if the position of center of the panel is less than half of the
      // page;
      if (center < _pageWidth / 2) {
        // Dock to the left edge;
        _positionLeft = 0.0 + _dockBoundary();
      } else {
        // Dock to the right edge;
        _positionLeft = (_pageWidth - _widgetSize) - _dockBoundary();
      }
    }

    // Animated positioned widget can be moved to any part of the screen with
    // animation;
    return SafeArea(
      child: SizedBox(
        width: _pageWidth,
        height: _pageHeight,
        child: Stack(
          children: [
            IgnorePointer(
              ignoring: _panelState == PanelState.closed,
              child: GestureDetector(
                onTap: (){
                  setState(() {
                    if(_panelState == PanelState.closed){
                      _panelState = PanelState.open;
                    }
                    else{
                      _panelState = PanelState.closed;
                    }
                    _positionTop = 0.0;
                  });
                },
                child: AnimatedContainer(
                  width: _pageWidth,
                  height: _pageHeight,
                  duration: Duration(milliseconds: 300),
                  color: _panelState == PanelState.open? Colors.black.withOpacity(0.2):Colors.transparent,
                ),
              ),
            ),
            AnimatedPositioned(
              duration: Duration(
                milliseconds: _movementSpeed,
              ),
              top: _positionTop,
              left: _positionLeft,
              curve: widget.dockAnimCurve ?? Curves.fastLinearToSlowEaseIn,

              // Animated Container is used for easier animation of container height;
              child: Center(
                child: GestureDetector(
                  onPanEnd: (event) {
                    if(
                        (_positionTop <=  MediaQuery.of(context).size.height - (widget.size??70.0) && _positionTop >=  MediaQuery.of(context).size.height - 260 - (widget.size??70.0)) &&
                        ((_positionLeft + (widget.size??70.0)/2 ) >= MediaQuery.of(context).size.width/2 - 60  && (_positionLeft + (widget.size??70.0)/2 ) <= MediaQuery.of(context).size.width/2 + 60)
                    ){
                      setState(() {
                        _closed = true;
                      });
                      if(widget.onCloseCallBack!=null)
                        widget.onCloseCallBack();
                      return;
                    }
                    setState(
                      () {
                        _forceDock();
                      },
                    );
                    if(_dragging){
                      setState(() {
                        _dragging = false;
                      });
                    }
                  },
                  onPanStart: (event) {
                    // Detect the offset between the top and left side of the panel and
                    // x and y position of the touch(click) event;
                    _panOffsetTop = event.globalPosition.dy - _positionTop;
                    _panOffsetLeft = event.globalPosition.dx - _positionLeft;
                    if(!_dragging){
                      setState(() {
                        _dragging = true;
                      });
                    }
                  },
                  onPanUpdate: (event) {
                    setState(
                      () {
                        // Close Panel if opened;
                        _panelState = PanelState.closed;

                        // Reset Movement Speed;
                        _movementSpeed = 0;

                        // Calculate the top position of the panel according to pan;
                        _positionTop = event.globalPosition.dy - _panOffsetTop;

                        // Check if the top position is exceeding the dock boundaries;
                        if (_positionTop < 0 + _dockBoundary()) {
                          _positionTop = 0 + _dockBoundary();
                        }
                        if (_positionTop >
                            (_pageHeight - _panelHeight()) - _dockBoundary()) {
                          _positionTop =
                              (_pageHeight - _panelHeight()) - _dockBoundary();
                        }

                        // Calculate the Left position of the panel according to pan;
                        _positionLeft = event.globalPosition.dx - _panOffsetLeft;

                        // Check if the left position is exceeding the dock boundaries;
                        if (_positionLeft < 0 + _dockBoundary()) {
                          _positionLeft = 0 + _dockBoundary();
                        }
                        if (_positionLeft >
                            (_pageWidth - _widgetSize) - _dockBoundary()) {
                          _positionLeft =
                              (_pageWidth - _widgetSize) - _dockBoundary();
                        }
                      },
                    );
                  },
                  onTap: () {
                    setState(() {
                      if(_panelState == PanelState.closed){
                        _panelState = PanelState.open;
                        //_positionLeft = _openDockLeft();
                      }
                      else{
                        _panelState = PanelState.closed;
                        //_forceDock();
                      }
                      _positionTop = 0.0;
                    });
                    return;
                  },
                  child: widget.bubble,
                ),
              ),
            ),
            IgnorePointer(
                ignoring: _panelState != PanelState.open,
                child: AnimatedOpacity(
                  opacity: _panelState == PanelState.open?1.0:0.0,
                  duration: Duration(milliseconds: 200),
                  child: Container(
                    margin: EdgeInsets.only(top: widget.size??70.0),
                    child: widget.widget,
                  ),
                ),
              ),
            AnimatedPositioned(
              bottom: (_dragging?0.0:-200),
              duration: Duration(milliseconds: 200),
              child: AnimatedBuilder(
                builder: (BuildContext context, Widget child) {
                  return Transform.scale(
                    scale: _pulse.value,
                    child: child,
                  );
                },
                animation: _pulse,
                child: Container(
                  height: 200,
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(color: Colors.red , width: 3.0),
                        ),
                        padding: EdgeInsets.all(8),
                        child: Center(child: Icon(Icons.clear )),
                      )
                    ],
                  ),
                ),
              ),
            )

          ],
        ),
      ),
    );
  }
}

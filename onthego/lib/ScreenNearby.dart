import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/plugin_api.dart';
import 'dart:ui';

import 'globals.dart';
import 'global_functions.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

double lastPosition = 0;
double mapHeight = INITIAL_MAP_HEIGHT;

bool pullTabIcon = true;

bool back(setState) {
  if (currentStopNearby != null) {
    currentStopNearby = null;
    setState(() {});
  }
  return false;
}

List<Widget> buildNearbyStops(context, setState, setStateParent) {
  if (currentNearbyStops == null) {
    return [Container()];
  }
  List nearbyStops = currentNearbyStops
      .map((item) => Container(
            height: MediaQuery.of(context).size.width * LIST_VIEW_ITEM_HEIGHT,
            child: TextButton(
              onPressed: () async {
                if (mapHeight != INITIAL_MAP_HEIGHT) {
                  mapHeight = INITIAL_MAP_HEIGHT;
                  setStateParent(() => {});
                } else {
                  currentStopNearby = item;
                  setStateParent(() => {});
                  await loadArrivalTimesNearby(setState);
                }
              },
              style: TextButton.styleFrom(backgroundColor: Color(0xffe8e8e8), padding: EdgeInsets.all(5)),
              child: Row(
                children: <Widget>[
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.only(left: MediaQuery.of(context).size.height * LIST_VIEW_ITEM_TEXT_SIZE),
                        child: Text(
                          item.commonName,
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: MediaQuery.of(context).size.height * LIST_VIEW_ITEM_TEXT_SIZE,
                          ),
                        ),
                      ),
                      item != null
                          ? Container(
                              padding: EdgeInsets.only(left: MediaQuery.of(context).size.height * LIST_VIEW_ITEM_TEXT_SIZE, top: MediaQuery.of(context).size.height * LIST_VIEW_ITEM_TEXT_SIZE / 4),
                              child: Text(
                                "ID " + item.naptanId + " | " + item.lines.join(" • "),
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: MediaQuery.of(context).size.height * LIST_VIEW_ITEM_TEXT_SIZE / 1.7,
                                ),
                              ),
                            )
                          : Container(),
                    ],
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      width: 100.0,
                      height: 100.0,
                    ),
                  ),
                  item != null
                      ? Container(
                          height: MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT - PULL_TAB_HEIGHT) * 0.8,
                          width: MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT - PULL_TAB_HEIGHT) * 0.8,
                          margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT - PULL_TAB_HEIGHT) * 0.2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.all(Radius.circular(MediaQuery.of(context).size.width * (LIST_VIEW_ITEM_HEIGHT - PULL_TAB_HEIGHT) * 0.6)),
                            color: Color(0xffe84545),
                          ),
                          child: Center(
                            child: item.stopLetter == null || item.stopLetter.toString().contains("->") || item.stopLetter == "Stop"
                                ? selectedToggle == 0
                                    ? Icon(
                                        Icons.directions_bus,
                                        color: Colors.white,
                                        size: 20,
                                      )
                                    : Icon(
                                        Icons.directions_train,
                                        color: Colors.white,
                                        size: 20,
                                      )
                                : Text(
                                    item.stopLetter.split("Stop ")[1],
                                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                          ),
                        )
                      : Container(),
                ],
              ),
            ),
          ))
      .toList();
  return nearbyStops;
}

class ScreenNearby extends StatefulWidget {
  @override
  _ScreenNearby createState() => _ScreenNearby();
}

class _ScreenNearby extends State<ScreenNearby> {
  @override
  void initState() {
    super.initState();
    readFavourites();
    mapController = MapController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return back(setState);
      },
      child: Stack(
        children: <Widget>[
          ListViewPage(setState),
          MapView(setState),
          TopBar(setState),
        ],
      ),
    );
  }
}

class TopBar extends StatefulWidget {
  Function setStateParent;

  TopBar(this.setStateParent);

  @override
  _TopBarState createState() => _TopBarState();
}

class _TopBarState extends State<TopBar> {
  TextEditingController searchController = TextEditingController(text: currentSearchString);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 0),
      padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
      decoration: BoxDecoration(
        color: Color(0xff53354a),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            spreadRadius: 1,
            offset: Offset(0, 3),
            blurRadius: 3,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Material(
                borderRadius:
                    BorderRadius.only(topLeft: Radius.circular(MediaQuery.of(context).size.height * TOGGLE_HEIGHT), bottomLeft: Radius.circular(MediaQuery.of(context).size.height * TOGGLE_HEIGHT)),
                color: selectedToggle == 0 ? Color(0xffe84545) : Colors.transparent,
                child: InkWell(
                  borderRadius:
                      BorderRadius.only(topLeft: Radius.circular(MediaQuery.of(context).size.height * TOGGLE_HEIGHT), bottomLeft: Radius.circular(MediaQuery.of(context).size.height * TOGGLE_HEIGHT)),
                  onTap: () async {
                    selectedToggle = 0;
                    if (showSearchInput && currentSearchString.length > 0) {
                      searchForStops(this.widget.setStateParent, currentSearchString);
                    } else {
                      await loadClosestStopArrivalTimes(this.widget.setStateParent);
                    }
                  },
                  child: AnimatedContainer(
                      height: MediaQuery.of(context).size.height * TOGGLE_HEIGHT,
                      width: (MediaQuery.of(context).size.width - (MediaQuery.of(context).size.height * (TOGGLE_BAR_HEIGHT - TOGGLE_HEIGHT) * 3 / 2)) * TOGGLE_WIDTH,
                      decoration: BoxDecoration(
                        color: selectedToggle == 0 ? Color(0xffe84545) : null,
                        borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(MediaQuery.of(context).size.height * TOGGLE_HEIGHT), bottomLeft: Radius.circular(MediaQuery.of(context).size.height * TOGGLE_HEIGHT)),
                        border: Border.all(color: Color(0xffe84545), width: 3),
                      ),
                      duration: Duration(milliseconds: ANIMATION_DURATION),
                      curve: Curves.fastOutSlowIn,
                      child: Center(
                        child: Icon(
                          Icons.directions_bus,
                          color: Colors.white,
                        ),
                      )),
                ),
              ),
              Material(
                borderRadius:
                    BorderRadius.only(topRight: Radius.circular(MediaQuery.of(context).size.height * TOGGLE_HEIGHT), bottomRight: Radius.circular(MediaQuery.of(context).size.height * TOGGLE_HEIGHT)),
                color: selectedToggle == 1 ? Color(0xffe84545) : Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.only(
                      topRight: Radius.circular(MediaQuery.of(context).size.height * TOGGLE_HEIGHT), bottomRight: Radius.circular(MediaQuery.of(context).size.height * TOGGLE_HEIGHT)),
                  onTap: () async {
                    selectedToggle = 1;
                    if (showSearchInput && currentSearchString.length > 0) {
                      searchForStops(this.widget.setStateParent, currentSearchString);
                    } else {
                      await loadClosestStopArrivalTimes(this.widget.setStateParent);
                    }
                  },
                  child: AnimatedContainer(
                      duration: Duration(milliseconds: ANIMATION_DURATION),
                      curve: Curves.easeInOut,
                      height: MediaQuery.of(context).size.height * TOGGLE_HEIGHT,
                      width: (MediaQuery.of(context).size.width - (MediaQuery.of(context).size.height * (TOGGLE_BAR_HEIGHT - TOGGLE_HEIGHT) * 3 / 2)) * TOGGLE_WIDTH,
                      decoration: BoxDecoration(
                        color: selectedToggle == 1 ? Color(0xffe84545) : null,
                        borderRadius: BorderRadius.only(
                            topRight: Radius.circular(MediaQuery.of(context).size.height * TOGGLE_HEIGHT), bottomRight: Radius.circular(MediaQuery.of(context).size.height * TOGGLE_HEIGHT)),
                        border: Border.all(color: Color(0xffe84545), width: 3),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.directions_train,
                          color: Colors.white,
                        ),
                      )),
                ),
              )
            ],
          ),
          showSearchInput
              ? Container(
                  margin: EdgeInsets.only(top: 10),
                  width: (MediaQuery.of(context).size.width - (MediaQuery.of(context).size.height * (TOGGLE_BAR_HEIGHT - TOGGLE_HEIGHT) * 3 / 2)) * TOGGLE_WIDTH * 2,
                  height: MediaQuery.of(context).size.height * TOGGLE_HEIGHT,
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    onSubmitted: (text) {
                      searchForStops(this.widget.setStateParent, text);
                    },
                    onChanged: (text) {
                      setState(() {});
                    },
                    cursorColor: Colors.blueGrey,
                    decoration: InputDecoration(
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(100)),
                        borderSide: BorderSide(color: Colors.white, width: 5),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(100)),
                        borderSide: BorderSide(color: Colors.white, width: 5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(100)),
                        borderSide: BorderSide(color: Colors.white, width: 5),
                      ),
                      suffixIcon: IconButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() {});
                        },
                        icon: searchController.text.length > 0 ? Icon(Icons.clear, color: Colors.red) : Icon(Icons.clear, color: Colors.blueGrey),
                      ),
                      contentPadding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                      hintText: 'Search ...',
                    ),
                  ),
                )
              : Container(),
          GestureDetector(
            onTap: () {
              showSearchInput = !showSearchInput;
              setState(() {});
              if (!showSearchInput) {
                FocusScope.of(context).unfocus();
                if (currentSearchString != null) {
                  loadClosestStopArrivalTimes(setState);
                }
                currentSearchString = null;
              }
            },
            child: Container(
              padding: EdgeInsets.all(5),
              child: Icon(
                Icons.manage_search,
                color: showSearchInput ? Colors.white : Colors.white70,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class MapView extends StatefulWidget {
  Function setStateParent;

  MapView(this.setStateParent);

  @override
  _MapViewState createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        AnimatedContainer(
          margin: EdgeInsets.only(top: MediaQuery.of(context).size.height * TOGGLE_BAR_HEIGHT),
          duration: Duration(milliseconds: ANIMATION_DURATION),
          curve: Curves.easeOut,
          height: mapHeight,
          child: FlutterMap(
            mapController: mapController,
            options: new MapOptions(
              allowPanning: false,
              interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.doubleTapZoom | InteractiveFlag.pinchMove | InteractiveFlag.drag,
              center: currentLocation == null ? LatLng(51.507351, -0.127758) : LatLng(currentLocation.latitude, currentLocation.longitude),
              zoom: 15.0,
              maxZoom: 17.5,
              minZoom: 14.0,
            ),
            layers: [
              new TileLayerOptions(
                urlTemplate: "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png",
                subdomains: ['a', 'b', 'c', 'd'],
              ),
              new MarkerLayerOptions(
                markers: currentNearbyStops != null
                    ? () {
                        List<Marker> returnList = currentNearbyStops
                            .map(
                              (item) => Marker(
                                width: 20.0,
                                height: 20.0,
                                point: LatLng(item.lat, item.lon),
                                builder: (ctx) => GestureDetector(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(Radius.circular(5)),
                                      color: currentStopNearby == item ? Color(0xffe84545) : Colors.blueGrey.withAlpha(150),
                                    ),
                                    child: Center(
                                      child: item.stopLetter == null || item.stopLetter.toString().contains("->") || item.stopLetter == "Stop"
                                          ? selectedToggle == 0
                                              ? Icon(
                                                  Icons.directions_bus,
                                                  color: Colors.white,
                                                  size: 16,
                                                )
                                              : Icon(
                                                  Icons.directions_train,
                                                  color: Colors.white,
                                                  size: 16,
                                                )
                                          : Text(
                                              item.stopLetter.split("Stop ")[1],
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: MediaQuery.of(context).size.width * (LIST_VIEW_TITLE_BAR_HEIGHT - PULL_TAB_HEIGHT) * 0.6 * 0.25,
                                              ),
                                            ),
                                    ),
                                  ),
                                  onTap: () async {
                                    currentStopNearby = item;
                                    loadArrivalTimesNearby(this.widget.setStateParent);
                                  },
                                ),
                              ),
                            )
                            .toList();
                        if (currentLocation != null) {
                          returnList.add(Marker(
                            width: 80.0,
                            height: 80.0,
                            point: LatLng(currentLocation.latitude, currentLocation.longitude),
                            builder: (ctx) => Icon(
                              Icons.my_location,
                              color: Colors.blueGrey,
                              size: 25,
                            ),
                          ));
                        }
                        return returnList;
                      }()
                    : [],
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            if (mapHeight == INITIAL_MAP_HEIGHT) {
              mapHeight = MAX_MAP_HEIGHT;
              pullTabIcon = false;
            } else {
              mapHeight = INITIAL_MAP_HEIGHT;
              pullTabIcon = true;
            }
            setState(() {});
          },
          onVerticalDragStart: (details) {
            lastPosition = details.globalPosition.dy;
          },
          onVerticalDragUpdate: (details) {
            double change = details.globalPosition.dy - lastPosition;
            mapHeight += change;
            lastPosition = details.globalPosition.dy;
            if (mapHeight < INITIAL_MAP_HEIGHT) {
              mapHeight = INITIAL_MAP_HEIGHT;
            }
            if (mapHeight > MAX_MAP_HEIGHT) {
              mapHeight = MAX_MAP_HEIGHT;
            }
            if ((mapHeight - INITIAL_MAP_HEIGHT) / (MAX_MAP_HEIGHT - INITIAL_MAP_HEIGHT) > 0.5) {
              pullTabIcon = false;
            } else {
              pullTabIcon = true;
            }
            setState(() {});
          },
          onVerticalDragEnd: (details) {
            if (MAX_MAP_HEIGHT - mapHeight < 10) {
              mapHeight = MAX_MAP_HEIGHT;
              pullTabIcon = false;
            } else {
              if (details.primaryVelocity > 0) {
                mapHeight = MAX_MAP_HEIGHT;
                pullTabIcon = false;
              } else {
                mapHeight = INITIAL_MAP_HEIGHT;
                pullTabIcon = true;
              }
            }
            setState(() {});
          },
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height * PULL_TAB_HEIGHT,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(MediaQuery.of(context).size.height * PULL_TAB_HEIGHT), bottomLeft: Radius.circular(MediaQuery.of(context).size.height * PULL_TAB_HEIGHT)),
              color: Color(0xffe84545),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  spreadRadius: 0.1,
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                pullTabIcon ? Icons.arrow_drop_down : Icons.arrow_drop_up,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ListViewPage extends StatefulWidget {
  Function setStateParent;

  ListViewPage(this.setStateParent);

  @override
  _ListViewPageState createState() => _ListViewPageState();
}

class _ListViewPageState extends State<ListViewPage> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        mapHeight = INITIAL_MAP_HEIGHT;
        pullTabIcon = true;
        FocusScope.of(context).unfocus();
        this.widget.setStateParent(() {});
      },
      child: Container(
          margin: EdgeInsets.only(
            top: (MediaQuery.of(context).size.height * (TOGGLE_BAR_HEIGHT)) + INITIAL_MAP_HEIGHT,
          ),
          color: Color(0xffe8e8e8),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              AnimatedContainer(
                duration: Duration(milliseconds: ANIMATION_DURATION),
                curve: Curves.easeOut,
                padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * (PULL_TAB_HEIGHT)),
                color: Color(0xff903749),
                height: MediaQuery.of(context).size.width * LIST_VIEW_TITLE_BAR_HEIGHT,
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: <Widget>[
                    IconButton(
                        icon: Icon(
                          currentStopNearby != null ? Icons.arrow_back : null,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          mapHeight = INITIAL_MAP_HEIGHT;
                          pullTabIcon = true;
                          this.widget.setStateParent(() {});
                          back(setState);
                        }),
                    Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            Container(
                              padding: EdgeInsets.only(left: MediaQuery.of(context).size.height * LIST_VIEW_TITLE_BAR_TEXT_SIZE / 3),
                              child: loadingNearby
                                  ? Text(
                                      "Stations",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: MediaQuery.of(context).size.height * LIST_VIEW_TITLE_BAR_TEXT_SIZE,
                                      ),
                                    )
                                  : Text(
                                      currentStopNearby != null
                                          ? currentStopNearby.commonName.length > LIST_VIEW_TITLE_MAX_LENGTH
                                              ? currentStopNearby.commonName.replaceRange(LIST_VIEW_TITLE_MAX_LENGTH + 1, currentStopNearby.commonName.length, "...")
                                              : currentStopNearby.commonName
                                          : "Stations",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: MediaQuery.of(context).size.height * LIST_VIEW_TITLE_BAR_TEXT_SIZE,
                                      ),
                                    ),
                            ),
                            currentStopNearby != null ? Container() : Container(),
                          ],
                        ),
                        currentStopNearby != null
                            ? Container(
                                padding: EdgeInsets.only(
                                    left: MediaQuery.of(context).size.height * LIST_VIEW_TITLE_BAR_TEXT_SIZE / 3, top: MediaQuery.of(context).size.height * LIST_VIEW_TITLE_BAR_TEXT_SIZE / 4),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: <Widget>[
                                    Container(
                                      padding: EdgeInsets.only(
                                        right: MediaQuery.of(context).size.height * LIST_VIEW_TITLE_BAR_TEXT_SIZE / 3,
                                      ),
                                      child: Text(
                                        () {
                                          String text = "ID " + currentStopNearby.naptanId + " | " + currentStopNearby.lines.join(" • ");
                                          try {
                                            text = text.replaceRange(45, text.length, '...');
                                          } catch (e) {}
                                          return text;
                                        }(),
                                        overflow: TextOverflow.fade,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: MediaQuery.of(context).size.height * LIST_VIEW_TITLE_BAR_TEXT_SIZE / 1.7,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () {
                                        mapHeight = INITIAL_MAP_HEIGHT;
                                        pullTabIcon = true;
                                        this.widget.setStateParent(() {});
                                        if (currentFavourites.containsKey(currentStopNearby.naptanId)) {
                                          currentFavourites.removeWhere((key, value) => key == currentStopNearby.naptanId);
                                          writeFavourites();
                                          setState(() {});
                                        } else {
                                          currentFavourites[currentStopNearby.naptanId] = {
                                            "stopLetter": currentStopNearby.stopLetter,
                                            "commonName": currentStopNearby.commonName,
                                            "distance": currentStopNearby.distance,
                                            "lat": currentStopNearby.lat,
                                            "lon": currentStopNearby.lon,
                                            "lines": currentStopNearby.lines,
                                          };
                                          writeFavourites();
                                          setState(() {});
                                        }
                                        favouritesChanged = true;
                                      },
                                      child: Icon(
                                        currentFavourites.containsKey(currentStopNearby.naptanId) ? Icons.favorite : Icons.favorite_border,
                                        color: Color(0xffe84545),
                                        size: 17,
                                      ),
                                    )
                                  ],
                                ),
                              )
                            : Container(),
                      ],
                    ),
                    Expanded(
                      flex: 1,
                      child: Container(),
                    ),
                    currentStopNearby != null
                        ? Container(
                            margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * (LIST_VIEW_TITLE_BAR_HEIGHT - PULL_TAB_HEIGHT) * 0.2),
                            height: MediaQuery.of(context).size.width * (LIST_VIEW_TITLE_BAR_HEIGHT - PULL_TAB_HEIGHT) * 0.5,
                            width: MediaQuery.of(context).size.width * (LIST_VIEW_TITLE_BAR_HEIGHT - PULL_TAB_HEIGHT) * 0.5,
                            child: Material(
                              borderRadius: BorderRadius.all(Radius.circular(MediaQuery.of(context).size.width * (LIST_VIEW_TITLE_BAR_HEIGHT - PULL_TAB_HEIGHT) * 0.6)),
                              color: Color(0xffe84545),
                              child: InkWell(
                                borderRadius: BorderRadius.all(Radius.circular(MediaQuery.of(context).size.width * (LIST_VIEW_TITLE_BAR_HEIGHT - PULL_TAB_HEIGHT) * 0.6)),
                                onTap: () {
                                  mapHeight = INITIAL_MAP_HEIGHT;
                                  this.widget.setStateParent(() {});
                                  mapController.onReady.then((value) {
                                    mapController.move(LatLng(currentStopNearby.lat, currentStopNearby.lon), mapController.zoom);
                                  });
                                },
                                child: Container(
                                  child: Center(
                                    child: currentStopNearby.stopLetter == null || currentStopNearby.stopLetter.toString().contains("->") || currentStopNearby.stopLetter == "Stop"
                                        ? selectedToggle == 0
                                            ? Icon(
                                                Icons.directions_bus,
                                                color: Colors.white,
                                              )
                                            : Icon(
                                                Icons.directions_train,
                                                color: Colors.white,
                                              )
                                        : Text(
                                            currentStopNearby.stopLetter.split("Stop ")[1],
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: MediaQuery.of(context).size.width * (LIST_VIEW_TITLE_BAR_HEIGHT - PULL_TAB_HEIGHT) * 0.6 * 0.4,
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : Container(),
                  ],
                ),
              ),
              Expanded(
                child: loadingNearby
                    ? Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: () async {
                          mapHeight = INITIAL_MAP_HEIGHT;
                          pullTabIcon = true;
                          this.widget.setStateParent(() {});
                          if (currentStopNearby == null) {
                            loadNearbyStops(setState);
                          } else {
                            loadArrivalTimesNearby(setState);
                          }
                        },
                        child: ListView(children: currentStopNearby == null ? buildNearbyStops(context, setState, this.widget.setStateParent) : buildArrivalTimes(context, 0)),
                      ),
              )
            ],
          )),
    );
  }
}

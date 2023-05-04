import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool choolCheckDone = false;
  GoogleMapController? mapController;

  // latitude, longitude
  static final LatLng companyLatLng = LatLng(
    37.5233273,
    126.921252,
  );

  // 초기 latitude, longitude, zoom 설정
  static final CameraPosition initialPosition = CameraPosition(
    target: companyLatLng,
    zoom: 15,
  );

  static final double okDistance = 100;
  static final Circle withinDistanceCircle = Circle(
    circleId: CircleId('withinDistanceCircle'), // 원의 고유 아이디
    center: companyLatLng, // 원의 중심 값
    fillColor: Colors.blue.withOpacity(0.5), // 원의 색
    radius: okDistance, // 원의 반지름
    strokeColor: Colors.blue, // 원 테두리 색
    strokeWidth: 1, // 원 테두리 두께
  );

  static final Circle notWithinDistanceCircle = Circle(
    circleId: CircleId('notWithinDistanceCircle'), // 원의 고유 아이디
    center: companyLatLng, // 원의 중심 값
    fillColor: Colors.red.withOpacity(0.5), // 원의 색
    radius: okDistance, // 원의 반지름
    strokeColor: Colors.red, // 원 테두리 색
    strokeWidth: 1, // 원 테두리 두께
  );

  static final Circle checkDoneDistanceCircle = Circle(
    circleId: CircleId('checkDoneDistanceCircle'), // 원의 고유 아이디
    center: companyLatLng, // 원의 중심 값
    fillColor: Colors.green.withOpacity(0.5), // 원의 색
    radius: okDistance, // 원의 반지름
    strokeColor: Colors.green, // 원 테두리 색
    strokeWidth: 1, // 원 테두리 두께
  );

  static final Marker marker = Marker(
    markerId: MarkerId('marker'),
    position: companyLatLng,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: renderAppBar(),
      body: FutureBuilder(
        // future에 있는 함수의 리턴을 받거나 리턴 값이 변경될 때마다, builder에 있는 함수가 재실행 됨
        future: checkPermission(),
        // 그리고, future 함수의 리턴 값을 AsyncSnapshot을 통해 받을 수 있음
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          // connectionState => AsyncSnapshot(future 함수)의 상태 (wait, done)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          // AsyncSnapshot(future 함수)의 리턴 값
          if (snapshot.data == '위치 권한이 허가되었습니다.') {
            return StreamBuilder<Position>(
                // position이 바뀔 때마다 실행, 위치 권한이 허가되어야만 해당 함수 실행 가능
                stream: Geolocator.getPositionStream(),
                builder: (context, snapshot) {
                  bool isWithinRange = false;

                  if (snapshot.hasData) {
                    final start = snapshot.data!;
                    final end = companyLatLng;
                    final distance = Geolocator.distanceBetween(
                      start.latitude,
                      start.longitude,
                      end.latitude,
                      end.longitude,
                    );

                    if (distance < okDistance) {
                      isWithinRange = true;
                    }
                  }

                  return Column(
                    children: [
                      _CustomGoogleMap(
                        initialPosition: initialPosition,
                        circle: choolCheckDone
                            ? checkDoneDistanceCircle
                            : isWithinRange
                                ? withinDistanceCircle
                                : notWithinDistanceCircle,
                        marker: marker,
                        onMapCreated: onMapCreated,
                      ),
                      _ChoolCheckButton(
                        isWithinRange: isWithinRange,
                        choolCheckDone: choolCheckDone,
                        onPressed: onChoolCheckPressed,
                      ),
                    ],
                  );
                });
          }

          return Center(
            child: Text(
              snapshot.data,
            ),
          );
        },
      ),
    );
  }

  AppBar renderAppBar() {
    return AppBar(
      title: Text(
        '오늘도 출근',
        style: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.w700,
        ),
      ),
      backgroundColor: Colors.white,
      actions: [
        IconButton(
          onPressed: () async {
            if (mapController == null) {
              print('mapController null');
              return;
            }

            final location = await Geolocator.getCurrentPosition();

            mapController!.animateCamera(
              CameraUpdate.newLatLng(
                LatLng(
                  location.latitude,
                  location.longitude,
                ),
              ),
            );
          },
          color: Colors.blue,
          icon: Icon(
            Icons.my_location,
          ),
        ),
      ],
    );
  }

  checkPermission() async {
    // location service 활성화 체크
    final isLocationEnabled = await Geolocator.isLocationServiceEnabled();
    if (!isLocationEnabled) {
      return '위치 서비스를 활성화해주세요.';
    }

    // location permission 체크
    LocationPermission checkedPermission = await Geolocator.checkPermission();
    if (checkedPermission == LocationPermission.denied) {
      // 권한 요청 alert 호출
      checkedPermission = await Geolocator.requestPermission();
      if (checkedPermission == LocationPermission.denied) {
        return '위치 권한을 허가해주세요.';
      }
    }

    if (checkedPermission == LocationPermission.deniedForever) {
      return '위치 권한을 시스템 세팅에서 허가해주세요.';
    }

    return '위치 권한이 허가되었습니다.';
  }

  // 값을 받아오고 싶으면, async & await를 사용해야 함
  onChoolCheckPressed() async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('출근하기'),
          content: Text('출근하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () {
                // dialog close & false return
                Navigator.of(context).pop(false);
              },
              child: Text('취소'),
            ),
            TextButton(
              onPressed: () {
                // dialog close & true return
                Navigator.of(context).pop(true);
              },
              child: Text('출근하기'),
            ),
          ],
        );
      },
    );

    if (result) {
      setState(() {
        choolCheckDone = true;
      });
    }
  }

  onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }
}

class _CustomGoogleMap extends StatelessWidget {
  final CameraPosition initialPosition;
  final Circle circle;
  final Marker marker;
  final MapCreatedCallback onMapCreated;

  const _CustomGoogleMap({
    required this.initialPosition,
    required this.circle,
    required this.marker,
    required this.onMapCreated,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: GoogleMap(
        mapType: MapType.normal,
        initialCameraPosition: initialPosition,
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        circles: Set.from([circle]),
        markers: Set.from([marker]),
        onMapCreated: onMapCreated,
      ),
    );
  }
}

class _ChoolCheckButton extends StatelessWidget {
  final bool isWithinRange;
  final VoidCallback onPressed;
  final bool choolCheckDone;

  const _ChoolCheckButton({
    required this.isWithinRange,
    required this.onPressed,
    required this.choolCheckDone,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timelapse_outlined,
            size: 50.0,
            color: choolCheckDone
                ? Colors.green
                : isWithinRange
                    ? Colors.blue
                    : Colors.red,
          ),
          const SizedBox(
            height: 20.0,
          ),
          if (!choolCheckDone && isWithinRange) // false면 아래 버튼 hide
            TextButton(
              onPressed: onPressed,
              child: Text(
                '출근하기',
              ),
            ),
        ],
      ),
    );
  }
}

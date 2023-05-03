import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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

  static final double distance = 100;
  static final Circle circle = Circle(
    circleId: CircleId('circle'), // 원의 고유 아이디
    center: companyLatLng, // 원의 중심 값
    fillColor: Colors.blue.withOpacity(0.5), // 원의 색
    radius: distance, // 원의 반지름
    strokeColor: Colors.blue, // 원 테두리 색
    strokeWidth: 1, // 원 테두리 두께
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
            return Column(
              children: [
                _CustomGoogleMap(
                  initialPosition: initialPosition,
                ),
                _ChoolCheckButton(),
              ],
            );
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
}

class _CustomGoogleMap extends StatelessWidget {
  final CameraPosition initialPosition;

  const _CustomGoogleMap({
    required this.initialPosition,
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
      ),
    );
  }
}

class _ChoolCheckButton extends StatelessWidget {
  const _ChoolCheckButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        '출근',
      ),
    );
  }
}

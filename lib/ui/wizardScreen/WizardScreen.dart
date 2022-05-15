import 'package:flutter/material.dart';
import 'package:health/health.dart';

import 'package:run_tracker/ui/WelcomeDialogScreen.dart';
import 'package:run_tracker/ui/weeklygoalSetScreen/WeeklyGoalSetScreenIntro.dart';
import 'package:run_tracker/ui/wizardScreen/GenderScreen.dart';
import 'package:run_tracker/ui/wizardScreen/HeightScreen.dart';
import 'package:run_tracker/ui/wizardScreen/WeightScreen.dart';
import 'package:run_tracker/utils/Color.dart';


class WizardScreen extends StatefulWidget {
  const WizardScreen({Key? key}) : super(key: key);

  @override
  WizardScreenState createState() => WizardScreenState();
}

class WizardScreenState extends State<WizardScreen> {
  double? _updateValue;
  PageController pageController = new PageController();
  bool isBack = false;
  late int pageNum;
  HealthFactory health = HealthFactory();

  String? genderSelected;
  int? weightSelected;
  int? heightSelected;

  Future fetchData() async {
    List<HealthDataPoint> _healthDataList = [];
    // define the types to get
    final types = [
      HealthDataType.STEPS,
      HealthDataType.WEIGHT,
      HealthDataType.HEIGHT,
      HealthDataType.BLOOD_GLUCOSE,
      // Uncomment this line on iOS - only available on iOS
      // HealthDataType.DISTANCE_WALKING_RUNNING,
    ];

    // with coresponsing permissions
    final permissions = [
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
      HealthDataAccess.READ,
    ];

    // get data within the last 24 hours
    final now = DateTime.now();
    final yesterday = now.subtract(Duration(days: 1));

    // requesting access to the data types before reading them
    // note that strictly speaking, the [permissions] are not
    // needed, since we only want READ access.
    bool requested =
    await health.requestAuthorization(types, permissions: permissions);

    if (requested) {
      try {
        // fetch health data
        List<HealthDataPoint> healthData =
        await health.getHealthDataFromTypes(yesterday, now, types);

        // save all the new data points (only the first 100)
        _healthDataList.addAll((healthData.length < 100)
            ? healthData
            : healthData.sublist(0, 100));
      } catch (error) {
        print("Exception in getHealthDataFromTypes: $error");
      }

      // filter out duplicates
      _healthDataList = HealthFactory.removeDuplicates(_healthDataList);

      // print the results
      _healthDataList.forEach((item) {
        if(item.type == HealthDataType.WEIGHT) {
          print(item.value);
          try {
            weightSelected = item.value.toInt();
            print(weightSelected);
          } catch (e) {

          }
        }
        if(item.type == HealthDataType.HEIGHT) {
          print(item.value);
          try {
             heightSelected = item.value.toInt()*100;
            print(heightSelected);
          } catch (e) {

          }
        }
        if(item.type == HealthDataType.STEPS) {
          print(item.value);
        }
      });

      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => WeeklyGoalSetScreen(
              weight: weightSelected ?? 60,
              height: heightSelected ?? 170,
              gender: genderSelected ?? "Male",
            )
        ),
      );


      // update the UI to display the results

    } else {
      print("Authorization not granted");
      // setState(() => _state = AppState.DATA_NOT_FETCHED);
    }
  }

  void onGender(String gender) {
    setState(() {
      genderSelected = gender;
    });
  }

  void onWeight(int weight) {
    setState(() {
      weightSelected = weight;
    });
  }


  @override
  void initState() {
    fetchData();
    super.initState();

    pageNum = 1;

    _updateValue = 0.33;

    Future.delayed(Duration(seconds: 1), () {
      showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          isDismissible: true,
          enableDrag: false,
          builder: (context) {
            return Wrap(
              children: [
                WelcomeDialogScreen(),
              ],
            );
          });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: MediaQuery
            .of(context)
            .size
            .height,
        width: MediaQuery
            .of(context)
            .size
            .width,
        color: Colur.common_bg_dark,
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                child: _progressTopBar(),
              ),
              Flexible(
                flex: 9,
                child: new PageView(
                  onPageChanged:(pos){
                    setState(() {
                      isBack = (pos!=0);
                    });
                  },
                  controller: pageController,
                  physics: new NeverScrollableScrollPhysics(),
                  children: <Widget>[
                    GenderScreen(
                      pageController: pageController,
                      updatevalue: updateValue,
                      isBack:isBack,
                      pageNum:updagePageNumber,
                      onGender: onGender,
                      gender: genderSelected,
                      wizardScreenState: this,
                    ),
                    WeightScreen(
                      pageController: pageController,
                      updatevalue: updateValue,
                      isBack:isBack,
                      pageNum:updagePageNumber,
                      onWeight: onWeight,
                      wizardScreenState: this,
                      weight: weightSelected,
                    ),
                    HeightScreen(
                      isBack:isBack,
                      wizardScreenState: this,
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  updateValue(double progress) {
    setState(() {
      _updateValue = progress;
      if (_updateValue!.toStringAsFixed(1) == '1.2') {
        _updateValue = 0.0;
        return;
      }
    });
  }
  updagePageNumber(int newnum){
    setState(() {
      pageNum = newnum;
    });
  }


  _progressTopBar() {
    return Container(
      alignment: Alignment.center,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Visibility(
            visible: isBack,
            child: InkWell(
              onTap: () {
                if (pageController.hasClients) {

                  if (pageController.page!.round() == 0) {
                    setState(() {
                      isBack = false;
                    });
                  }
                  if(pageController.page!.round() != 0) {
                    pageController.previousPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                    updateValue(_updateValue! - 0.30);
                    updagePageNumber(pageNum -1);
                  }
                }

              },
              child: Container(
                  margin: EdgeInsets.only(left: 10),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      border: Border.all(
                        color: Colur.rounded_rectangle_color,
                      ),
                      borderRadius:
                      BorderRadius.all(Radius.circular(20))),
                  child: Center(
                      child: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colur.white,
                      ))),
            ),
          ),
          if(!isBack)
            Container(
              height: 50,
              width: 60,
            ),
          Expanded(
            child: UnconstrainedBox(
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(30.0)),
                child: Container(
                  width: 100,
                  child: LinearProgressIndicator(
                    backgroundColor: Colur.progress_background_color,
                    valueColor: new AlwaysStoppedAnimation<Color>(
                        Colur.purple_gradient_color2),
                    minHeight: 8,
                    value: _updateValue,
                  ),
                ),),
            ),
          ),
          Container(
            margin: EdgeInsets.only(right: 10),
            child: Text(
              pageNum.toString()+"/3",
              style: TextStyle(
                  color: Colur.txt_white,
                  fontSize: 20,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

}
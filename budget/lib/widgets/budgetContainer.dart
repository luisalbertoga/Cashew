import 'package:budget/database/tables.dart';
import 'package:budget/main.dart';
import 'package:budget/pages/budgetPage.dart';
import 'package:animations/animations.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/widgets/categoryEntry.dart';
import 'package:budget/widgets/fadeIn.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';
import '../colors.dart';
import '../functions.dart';
import '../struct/budget.dart';

class BudgetContainer extends StatelessWidget {
  BudgetContainer({Key? key, required this.budget, this.height = 183})
      : super(key: key);

  final Budget budget;
  final double height;

  @override
  Widget build(BuildContext context) {
    DateTimeRange budgetRange = getBudgetDate(budget, DateTime.now());
    var widget = (StreamBuilder<List<CategoryWithTotal>>(
      stream: database.watchTotalSpentInEachCategoryInTimeRangeFromCategories(
        budgetRange.start,
        budgetRange.end,
        budget.categoryFks ?? [],
        budget.allCategoryFks,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasData && (snapshot.data ?? []).length > 0) {
          double totalSpent = 0;
          snapshot.data!.forEach((category) {
            totalSpent = totalSpent + category.total;
          });
          return Container(
            height: height,
            child: ClipRRect(
              clipBehavior: Clip.antiAlias,
              borderRadius: BorderRadius.circular(15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Stack(
                    children: [
                      Positioned.fill(
                        child: AnimatedGooBackground(
                          randomOffset: budget.name.length,
                          color: HexColor(budget.colour).withOpacity(0.8),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 23, right: 23, bottom: 14, top: 13),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              width: double.infinity,
                              child: TextFont(
                                text: budget.name,
                                fontWeight: FontWeight.bold,
                                fontSize: 25,
                                textAlign: TextAlign.left,
                              ),
                            ),
                            budget.amount - totalSpent >= 0
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        child: CountUp(
                                          count: budget.amount - totalSpent,
                                          prefix: getCurrencyString(),
                                          duration:
                                              Duration(milliseconds: 2500),
                                          fontSize: 18,
                                          textAlign: TextAlign.left,
                                          fontWeight: FontWeight.bold,
                                          decimals:
                                              moneyDecimals(budget.amount),
                                        ),
                                      ),
                                      Container(
                                        child: TextFont(
                                          text: " left of " +
                                              convertToMoney(budget.amount),
                                          fontSize: 13,
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        child: CountUp(
                                          count:
                                              -1 * (budget.amount - totalSpent),
                                          prefix: getCurrencyString(),
                                          duration:
                                              Duration(milliseconds: 2500),
                                          fontSize: 18,
                                          textAlign: TextAlign.left,
                                          fontWeight: FontWeight.bold,
                                          decimals:
                                              moneyDecimals(budget.amount),
                                        ),
                                      ),
                                      Container(
                                        padding:
                                            const EdgeInsets.only(bottom: 1.5),
                                        child: TextFont(
                                          text: " overspent of " +
                                              convertToMoney(budget.amount),
                                          fontSize: 13,
                                          textAlign: TextAlign.left,
                                        ),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: BudgetTimeline(
                      budget: budget,
                      percent: totalSpent / budget.amount * 100,
                      todayPercent:
                          getPercentBetweenDates(budgetRange, DateTime.now()),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(left: 10, right: 10, bottom: 17),
                    child: DaySpending(
                      budget: budget,
                      amount: (budget.amount - totalSpent) /
                          daysBetween(DateTime.now(), budgetRange.end),
                    ),
                  ),
                ],
              ),
            ),
          );
        } else {
          return SizedBox();
        }
      },
    ));
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 5.0,
        vertical: 0,
      ),
      child: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).brightness == Brightness.light
                  ? Theme.of(context).colorScheme.shadowColorLight.withAlpha(50)
                  : Colors.transparent,
              blurRadius: 20,
              offset: Offset(0, 2),
              spreadRadius: 8,
            ),
          ],
        ),
        child: OpenContainer<bool>(
          transitionType: ContainerTransitionType.fade,
          openBuilder: (BuildContext context, VoidCallback _) {
            return BudgetPage(budget: budget);
          },
          onClosed: () {}(),
          closedColor: Theme.of(context).canvasColor,
          tappable: false,
          closedShape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
          ),
          middleColor: Theme.of(context).colorScheme.white,
          transitionDuration: Duration(milliseconds: 500),
          closedElevation: 0.0,
          openColor: Theme.of(context).canvasColor,
          closedBuilder: (BuildContext _, VoidCallback openContainer) {
            return Tappable(
              onTap: () {
                openContainer();
              },
              borderRadius: 20,
              child: widget,
              color: Theme.of(context).colorScheme.lightDarkAccent,
            );
          },
        ),
      ),
    );
  }
}

class DaySpending extends StatelessWidget {
  const DaySpending({
    Key? key,
    required Budget this.budget,
    required double this.amount,
    bool this.large = false,
  }) : super(key: key);

  final Budget budget;
  final bool large;
  final double amount;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.fitWidth,
        child: TextFont(
          text:
              "You can keep spending " + convertToMoney(amount) + " each day.",
          fontSize: large ? 17 : 15,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class AnimatedGooBackground extends StatelessWidget {
  const AnimatedGooBackground({
    Key? key,
    required this.color,
    this.randomOffset = 1,
  });

  final Color color;
  final int randomOffset;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(200),
      ),
      child: PlasmaRenderer(
        type: PlasmaType.infinity,
        particles: 10,
        color: Theme.of(context).brightness == Brightness.light
            ? this.color.withOpacity(0.1)
            : this.color.withOpacity(0.3),
        blur: 0.3,
        size: 1.3,
        speed: 3.3,
        offset: 0,
        blendMode: BlendMode.multiply,
        particleType: ParticleType.atlas,
        variation1: 0,
        variation2: 0,
        variation3: 0,
        rotation:
            (randomInt % (randomOffset > 0 ? randomOffset : 1)).toDouble(),
      ),
    );
  }
}

class BudgetTimeline extends StatelessWidget {
  BudgetTimeline({
    Key? key,
    required this.budget,
    this.large = false,
    this.percent = 0,
    this.todayPercent = 0,
  }) : super(key: key);

  final Budget budget;
  final double todayPercent;
  final bool large;
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            large
                ? Container()
                : TextFont(
                    textAlign: TextAlign.center,
                    text: getWordedDateShort(
                        getBudgetDate(budget, DateTime.now()).start,
                        includeYear:
                            budget.reoccurrence == BudgetReoccurence.yearly),
                    fontSize: large ? 16 : 12,
                  ),
            Expanded(
              child: BudgetProgress(
                color: HexColor(budget.colour),
                percent: percent,
                todayPercent: todayPercent,
                large: large,
              ),
            ),
            large
                ? Container()
                : TextFont(
                    textAlign: TextAlign.center,
                    text: getWordedDateShort(
                        getBudgetDate(budget, DateTime.now()).end,
                        includeYear:
                            budget.reoccurrence == BudgetReoccurence.yearly),
                    fontSize: large ? 16 : 12,
                  ),
          ],
        ),
        large
            ? Container(
                padding: EdgeInsets.only(top: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextFont(
                      textAlign: TextAlign.center,
                      text: getWordedDateShortMore(
                          getBudgetDate(budget, DateTime.now()).start,
                          includeYear:
                              budget.reoccurrence == BudgetReoccurence.yearly),
                      fontSize: large ? 15 : 12,
                    ),
                    TextFont(
                      textAlign: TextAlign.center,
                      text: getWordedDateShortMore(
                          getBudgetDate(budget, DateTime.now()).end,
                          includeYear:
                              budget.reoccurrence == BudgetReoccurence.yearly),
                      fontSize: large ? 15 : 12,
                    ),
                  ],
                ),
              )
            : Container()
      ],
    );
  }
}

//put the today marker in
//use proper date time objects
class BudgetProgress extends StatelessWidget {
  BudgetProgress(
      {Key? key,
      required this.color,
      required this.percent,
      required this.todayPercent,
      this.large = false})
      : super(key: key);

  final Color color;
  final double percent;
  final double todayPercent;
  final bool large;

  @override
  Widget build(BuildContext context) {
    var percentText = Container(
      child: Center(
        child: CountUp(
          count: percent,
          textColor: Colors.black,
          decimals: 0,
          suffix: "%",
          fontSize: large ? 16 : 14,
          textAlign: TextAlign.center,
          fontWeight: FontWeight.bold,
          curve: Curves.decelerate,
          duration: Duration(milliseconds: 1500),
        ),
      ),
    );
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: darken(color, 0.5)),
          margin: EdgeInsets.symmetric(horizontal: 8),
          height: large ? 25 : 20,
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SlideFadeTransition(
              animationDuration: Duration(milliseconds: 1400),
              reverse: true,
              direction: Direction.horizontal,
              child: Container(
                  child: FractionallySizedBox(
                    heightFactor: 1,
                    widthFactor: percent / 100,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color:
                                  color), //can change this color to tint the progress bar
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                        percent > 30 ? percentText : Container(),
                      ],
                    ),
                  ),
                  height: large ? 25 : 20),
            ),
          ),
        ),
        TodayIndicator(
          percent: todayPercent,
          large: large,
        ),
        percent <= 40 ? percentText : Container(),
      ],
    );
  }
}

class TodayIndicator extends StatelessWidget {
  TodayIndicator({Key? key, required this.percent, this.large = false})
      : super(key: key);

  final double percent;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: FractionalOffset(percent / 100, 0),
      child: Container(
        child: Container(
          width: 20,
          height: large ? 45 : 39,
          child: OverflowBox(
            maxWidth: 500,
            child: SizedBox(
              width: 38,
              child: Column(
                children: [
                  SlideFadeTransition(
                    child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: Theme.of(context).colorScheme.black),
                        child: Padding(
                          padding: EdgeInsets.only(
                              top: 3, right: 5, left: 5, bottom: 3),
                          child: TextFont(
                            textAlign: TextAlign.center,
                            text: "Today",
                            fontSize: large ? 10 : 9,
                            textColor: Theme.of(context).colorScheme.white,
                          ),
                        )),
                  ),
                  FadeIn(
                    child: Container(
                      width: 3,
                      height: large ? 27 : 22,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(5)),
                        color: Theme.of(context)
                            .colorScheme
                            .black
                            .withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

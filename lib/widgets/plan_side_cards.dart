import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../state/app_state.dart';
import '../utils/format.dart';

class _SideCard extends StatelessWidget {
  const _SideCard({required this.border, required this.child});

  final Color border;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1.4),
      ),
      child: child,
    );
  }
}

const _titleStyle = TextStyle(fontSize: 11, fontWeight: FontWeight.w600);
const _smallStyle = TextStyle(fontSize: 10, color: AppColors.textMuted);

/// Current weather and 3-day outlook for the trip's city.
class WeatherCard extends StatelessWidget {
  const WeatherCard({super.key, required this.city});

  final String city;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final weather = state.weatherFor(city);
    final loading = state.isWeatherLoading(city);
    if (weather == null && !loading) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => state.refreshWeather(city),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.weatherBorder, width: 1.4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
            child: Column(
              children: [
                Text(
                  'อากาศวันนี้ $city',
                  textAlign: TextAlign.center,
                  style: _titleStyle,
                ),
                const SizedBox(height: 4),
                if (weather != null) ...[
                  Text(
                    '${weather.temp.round()}°C',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    weather.description,
                    style: _smallStyle,
                    textAlign: TextAlign.center,
                  ),
                ] else if (loading)
                  const Padding(
                    padding: EdgeInsets.all(6),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                else
                  const Text('โหลดข้อมูลไม่ได้', style: _smallStyle),
              ],
            ),
          ),
          if (weather != null && weather.next.isNotEmpty)
            Container(
              color: AppColors.weatherInner,
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('3 วันถัดไป', style: _smallStyle),
                  for (final d in weather.next)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              thaiWeekdayDay(d.date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          ),
                          Text(
                            '${d.maxTemp.round()}°C',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Spent vs. budget with a progress bar.
class BudgetCard extends StatelessWidget {
  const BudgetCard({super.key, required this.spent, required this.budget});

  final double spent;
  final double budget;

  @override
  Widget build(BuildContext context) {
    final ratio = budget <= 0 ? 0.0 : spent / budget;
    final over = ratio > 1;
    return _SideCard(
      border: over ? AppColors.rateBorder : AppColors.budgetBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Text('สรุปงบประมาณ', style: _titleStyle)),
          const SizedBox(height: 4),
          const Text('ใช้ไปแล้ว', style: _smallStyle),
          Text(
            '${money(spent)} / ${money(budget)}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: over ? AppColors.delete : AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: ratio.clamp(0, 1),
                    minHeight: 5,
                    backgroundColor: AppColors.progressTrack,
                    color: over ? AppColors.delete : AppColors.statusDone,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${(ratio * 100).round()}%',
                style: const TextStyle(fontSize: 8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Live exchange rate from the trip currency to THB.
class RateCard extends StatelessWidget {
  const RateCard({super.key, required this.currency});

  final String currency;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => state.refreshRate(currency),
    );
    return _SideCard(
      border: AppColors.rateBorder,
      child: Column(
        children: [
          const Text('อัตราแลกเปลี่ยน', style: _titleStyle),
          const SizedBox(height: 2),
          Text(
            currency == 'THB'
                ? 'สกุลเงินบาท (THB)'
                : '1 $currency = ${rate(state.rateToThb(currency))} THB',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

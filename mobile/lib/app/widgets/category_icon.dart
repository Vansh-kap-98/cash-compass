import 'package:flutter/material.dart';

/// The glyph for a stored category.
///
/// The app records an emoji per category (`categoryIcons` in
/// `models/transaction.dart`) and the web app drew those directly. They cannot
/// be used on an [AppIconTile]: an emoji renders from a colour font whatever
/// style is applied, so a black tile with a white glyph is not achievable with
/// one — and a grid of colour emoji is the single loudest thing on an otherwise
/// monochrome page.
///
/// So a transaction's tile takes a line icon chosen from the same category. The
/// emoji is not discarded — it still identifies goals, where the user types it
/// themselves and it is genuinely theirs.
///
/// Keyed on the stored English category, like [categoryLabel]; an unrecognised
/// one gets the neutral glyph rather than nothing.
IconData categoryIcon(String stored) => switch (stored) {
      'Income' => Icons.payments_outlined,
      'Salary' => Icons.account_balance_outlined,
      'Freelance' => Icons.work_outline,
      'Groceries' => Icons.shopping_basket_outlined,
      'Transport' => Icons.directions_bus_outlined,
      'Housing' => Icons.home_outlined,
      'Utilities' => Icons.bolt_outlined,
      'Entertainment' => Icons.movie_outlined,
      'Food' => Icons.restaurant_outlined,
      'Shopping' => Icons.shopping_bag_outlined,
      'Health' => Icons.medical_services_outlined,
      'Travel' => Icons.flight_outlined,
      'Education' => Icons.school_outlined,
      'Savings' => Icons.savings_outlined,
      'Investment' => Icons.trending_up,
      'Business' => Icons.business_center_outlined,
      'Gift' => Icons.card_giftcard_outlined,
      _ => Icons.more_horiz,
    };

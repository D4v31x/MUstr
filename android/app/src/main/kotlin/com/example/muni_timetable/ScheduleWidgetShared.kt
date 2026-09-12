package com.example.muni_timetable

import android.content.Context
import android.content.res.Configuration
import java.util.Locale

// Each cached line: day|dateLabel|startTime|endTime|courseName|room|colorHex|timetableId|isToday(0/1)
internal const val SCHEDULE_FIELD_COUNT = 9

// Only "current" (0) and "next" (1) week data is precomputed and cached by Dart.
internal const val SCHEDULE_MAX_WEEK_OFFSET = 1

private const val SCHEDULE_STATE_PREFS = "schedule_widget_state"

internal fun scheduleWeekOffset(context: Context, appWidgetId: Int): Int =
    context.getSharedPreferences(SCHEDULE_STATE_PREFS, Context.MODE_PRIVATE)
        .getInt("week_offset_$appWidgetId", 0)

internal fun setScheduleWeekOffset(context: Context, appWidgetId: Int, offset: Int) {
    context.getSharedPreferences(SCHEDULE_STATE_PREFS, Context.MODE_PRIVATE)
        .edit()
        .putInt("week_offset_$appWidgetId", offset)
        .apply()
}

internal fun clearScheduleWeekOffsets(context: Context, appWidgetIds: IntArray) {
    val editor = context.getSharedPreferences(SCHEDULE_STATE_PREFS, Context.MODE_PRIVATE).edit()
    appWidgetIds.forEach {
        editor.remove("week_offset_$it")
        editor.remove("timetables_$it")
    }
    editor.apply()
}

// Returns null when the user has never configured this widget (show all
// imported timetables, unfiltered) - an explicitly saved but empty set is not
// possible since the config screen requires at least one timetable to be
// selected (when at least one is available).
internal fun scheduleSelectedTimetables(context: Context, appWidgetId: Int): Set<String>? {
    val raw = context.getSharedPreferences(SCHEDULE_STATE_PREFS, Context.MODE_PRIVATE)
        .getString("timetables_$appWidgetId", null) ?: return null
    return raw.split(",").filter { it.isNotBlank() }.toSet()
}

internal fun setScheduleSelectedTimetables(context: Context, appWidgetId: Int, timetableIds: Set<String>) {
    context.getSharedPreferences(SCHEDULE_STATE_PREFS, Context.MODE_PRIVATE)
        .edit()
        .putString("timetables_$appWidgetId", timetableIds.joinToString(","))
        .apply()
}

// Widget strings must follow the app's OWN language setting (saved by Dart as
// "app_language"), not the device's system locale - the two can differ.
internal fun localizedScheduleContext(context: Context, languageCode: String?): Context {
    val locale = Locale(
        when (languageCode) {
            "cs", "sk" -> languageCode
            else -> "en"
        },
    )
    val config = Configuration(context.resources.configuration)
    config.setLocale(locale)
    return context.createConfigurationContext(config)
}

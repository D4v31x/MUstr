package com.example.muni_timetable

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.view.View
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import es.antonborri.home_widget.HomeWidgetPlugin

class ScheduleRemoteViewsService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        ScheduleRemoteViewsFactory(applicationContext, intent)
}

private sealed class ScheduleListItem {
    data class DayHeader(val label: String) : ScheduleListItem()

    data class ScheduleRow(
        val timeRange: String,
        val course: String,
        val room: String,
        val color: Int,
        val isToday: Boolean,
    ) : ScheduleListItem()
}

private class ScheduleRemoteViewsFactory(
    private val context: Context,
    intent: Intent,
) : RemoteViewsService.RemoteViewsFactory {
    private val appWidgetId = intent.getIntExtra(
        AppWidgetManager.EXTRA_APPWIDGET_ID,
        AppWidgetManager.INVALID_APPWIDGET_ID,
    )
    private var items: List<ScheduleListItem> = emptyList()
    private var barWidthPx = 0
    private var barHeightPx = 0
    private var cornerRadiusPx = 0f
    private var todayRingColor = Color.WHITE

    override fun onCreate() = Unit

    override fun onDataSetChanged() {
        items = buildItems(context, appWidgetId)
        val density = context.resources.displayMetrics.density
        val options = AppWidgetManager.getInstance(context).getAppWidgetOptions(appWidgetId)
        val widthDp = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 260)
        // Approximates the row's final rendered width (widget width minus root padding).
        barWidthPx = (((widthDp - 24).coerceAtLeast(100)) * density).toInt()
        barHeightPx = (52 * density).toInt()
        cornerRadiusPx = 14 * density
        todayRingColor = context.getColor(R.color.widget_chip_today_background)
    }

    override fun onDestroy() = Unit

    override fun getCount(): Int = items.size

    override fun getViewAt(position: Int): RemoteViews = when (val item = items[position]) {
        is ScheduleListItem.DayHeader ->
            RemoteViews(context.packageName, R.layout.widget_day_header).apply {
                setTextViewText(R.id.item_day_header, item.label)
            }
        is ScheduleListItem.ScheduleRow ->
            RemoteViews(context.packageName, R.layout.widget_lesson_row).apply {
                setTextViewText(R.id.item_time, item.timeRange)
                setTextViewText(R.id.item_course, item.course)
                if (item.room.isNotBlank()) {
                    setTextViewText(R.id.item_room, item.room)
                    setViewVisibility(R.id.item_room, View.VISIBLE)
                } else {
                    setViewVisibility(R.id.item_room, View.GONE)
                }
                setImageViewBitmap(
                    R.id.item_bar_bg,
                    roundedBarBitmap(item.color, item.isToday),
                )
                setOnClickFillInIntent(R.id.item_bar, Intent())
            }
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 2

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true

    // Draws the lesson's actual app color as a rounded pill; today's lessons
    // also get a bright accent ring since the fill no longer signals "today".
    private fun roundedBarBitmap(color: Int, isToday: Boolean): Bitmap {
        val width = barWidthPx.coerceAtLeast(1)
        val height = barHeightPx.coerceAtLeast(1)
        val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val fillPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply { this.color = color }
        val rect = RectF(0f, 0f, width.toFloat(), height.toFloat())
        canvas.drawRoundRect(rect, cornerRadiusPx, cornerRadiusPx, fillPaint)
        if (isToday) {
            val strokeWidth = 3f * (context.resources.displayMetrics.density)
            val ringPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                this.color = todayRingColor
                style = Paint.Style.STROKE
                this.strokeWidth = strokeWidth
            }
            val inset = strokeWidth / 2f
            val ringRect = RectF(inset, inset, width - inset, height - inset)
            canvas.drawRoundRect(ringRect, cornerRadiusPx, cornerRadiusPx, ringPaint)
        }
        return bitmap
    }
}

private fun buildItems(context: Context, appWidgetId: Int): List<ScheduleListItem> {
    val offset = scheduleWeekOffset(context, appWidgetId)
    val linesKey = if (offset == 0) "schedule_lines_current" else "schedule_lines_next"
    val widgetData = HomeWidgetPlugin.getData(context)
    val rawLines = widgetData.getString(linesKey, null)
    val entries = rawLines
        ?.split("\n")
        ?.filter { it.isNotBlank() }
        ?.map { it.split("|") }
        ?.filter { it.size == SCHEDULE_FIELD_COUNT }
        ?: emptyList()
    val selectedTimetables = scheduleSelectedTimetables(context, appWidgetId)

    val result = mutableListOf<ScheduleListItem>()
    var lastDayKey: String? = null
    entries.forEach { fields ->
        val day = fields[0]
        val dateLabel = fields[1]
        val startTime = fields[2]
        val endTime = fields[3]
        val course = fields[4]
        val room = fields[5]
        val colorHex = fields[6]
        val timetableId = fields[7]
        val isToday = fields[8]
        val kind = fields[9]
        val endAtMillis = fields[10].toLongOrNull()
        val passesFilter = kind != "lesson" || selectedTimetables == null || selectedTimetables.contains(timetableId)
        val isFinishedLesson = kind == "lesson" &&
            endAtMillis != null &&
            endAtMillis <= System.currentTimeMillis()
        if (!passesFilter || isFinishedLesson) return@forEach
        val dayKey = "$day|$dateLabel"
        if (dayKey != lastDayKey) {
            result.add(ScheduleListItem.DayHeader("$day - $dateLabel"))
            lastDayKey = dayKey
        }
        result.add(
            ScheduleListItem.ScheduleRow(
                timeRange = if (endTime.isBlank()) startTime else "$startTime\u2013$endTime",
                course = course,
                room = room,
                color = parseLessonColor(colorHex),
                isToday = isToday == "1",
            ),
        )
    }
    return result
}

private fun parseLessonColor(colorHex: String): Int = try {
    Color.parseColor("#$colorHex")
} catch (_: IllegalArgumentException) {
    Color.parseColor("#005CA9")
}

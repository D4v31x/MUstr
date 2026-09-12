package com.example.muni_timetable

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import androidx.core.content.ContextCompat
import androidx.core.content.res.ResourcesCompat
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

private const val ACTION_NAV_WEEK = "com.example.muni_timetable.ACTION_NAV_WEEK"
private const val EXTRA_WEEK_DELTA = "week_delta"

class ScheduleWidgetProvider : HomeWidgetProvider() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action == ACTION_NAV_WEEK) {
            val appWidgetId = intent.getIntExtra(
                AppWidgetManager.EXTRA_APPWIDGET_ID,
                AppWidgetManager.INVALID_APPWIDGET_ID,
            )
            if (appWidgetId != AppWidgetManager.INVALID_APPWIDGET_ID) {
                val delta = intent.getIntExtra(EXTRA_WEEK_DELTA, 0)
                val offset = (scheduleWeekOffset(context, appWidgetId) + delta)
                    .coerceIn(0, SCHEDULE_MAX_WEEK_OFFSET)
                setScheduleWeekOffset(context, appWidgetId, offset)
                renderScheduleWidget(context, AppWidgetManager.getInstance(context), appWidgetId)
            }
            return
        }
        super.onReceive(context, intent)
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        appWidgetIds.forEach { widgetId ->
            renderScheduleWidget(context, appWidgetManager, widgetId, widgetData)
        }
    }

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        super.onDeleted(context, appWidgetIds)
        clearScheduleWeekOffsets(context, appWidgetIds)
    }
}

internal fun renderScheduleWidget(
    context: Context,
    appWidgetManager: AppWidgetManager,
    appWidgetId: Int,
    widgetData: SharedPreferences = HomeWidgetPlugin.getData(context),
) {
    val offset = scheduleWeekOffset(context, appWidgetId)
    val labelKey = if (offset == 0) "schedule_label_current" else "schedule_label_next"

    val views = RemoteViews(context.packageName, R.layout.schedule_widget)
    views.setImageViewBitmap(R.id.widget_brand, brandBitmap(context))
    views.setTextViewText(R.id.widget_week_label, widgetData.getString(labelKey, null) ?: "")

    val localized = localizedScheduleContext(context, widgetData.getString("app_language", null))
    views.setTextViewText(R.id.widget_empty, localized.getString(R.string.widget_no_more_classes))

    val serviceIntent = Intent(context, ScheduleRemoteViewsService::class.java).apply {
        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        data = Uri.parse("schedulewidget://list/$appWidgetId/$offset")
    }
    views.setRemoteAdapter(R.id.widget_list, serviceIntent)
    views.setEmptyView(R.id.widget_list, R.id.widget_empty)

    // Only show a direction's arrow when there's cached data to page to.
    views.setViewVisibility(R.id.widget_nav_prev, if (offset > 0) View.VISIBLE else View.GONE)
    views.setViewVisibility(
        R.id.widget_nav_next,
        if (offset < SCHEDULE_MAX_WEEK_OFFSET) View.VISIBLE else View.GONE,
    )
    views.setOnClickPendingIntent(R.id.widget_nav_prev, scheduleNavPendingIntent(context, appWidgetId, -1))
    views.setOnClickPendingIntent(R.id.widget_nav_next, scheduleNavPendingIntent(context, appWidgetId, 1))

    val launchIntent = context.packageManager.getLaunchIntentForPackage(context.packageName)
    if (launchIntent != null) {
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        views.setPendingIntentTemplate(R.id.widget_list, pendingIntent)
    }

    appWidgetManager.updateAppWidget(appWidgetId, views)
    appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_list)
}

// RemoteViews' XML `android:fontFamily` isn't reliably honored by every OEM
// launcher, so the MUNI brand wordmark is rendered as a bitmap instead.
private fun brandBitmap(context: Context): Bitmap {
    val density = context.resources.displayMetrics.density
    val textSizePx = 15f * density
    val typeface = ResourcesCompat.getFont(context, R.font.muni_bold)
    val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        this.typeface = typeface
        textSize = textSizePx
        color = ContextCompat.getColor(context, R.color.widget_title)
    }
    val text = "MUSTR"
    val width = paint.measureText(text).toInt().coerceAtLeast(1)
    val metrics = paint.fontMetrics
    val height = (metrics.bottom - metrics.top).toInt().coerceAtLeast(1)
    val bitmap = Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
    Canvas(bitmap).drawText(text, 0f, -metrics.top, paint)
    return bitmap
}

private fun scheduleNavPendingIntent(context: Context, appWidgetId: Int, delta: Int): PendingIntent {
    val intent = Intent(context, ScheduleWidgetProvider::class.java).apply {
        action = ACTION_NAV_WEEK
        putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
        putExtra(EXTRA_WEEK_DELTA, delta)
    }
    // Distinct per (widget, direction) so the PendingIntents don't overwrite each other.
    val requestCode = appWidgetId * 10 + if (delta < 0) 1 else 2
    return PendingIntent.getBroadcast(
        context,
        requestCode,
        intent,
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )
}

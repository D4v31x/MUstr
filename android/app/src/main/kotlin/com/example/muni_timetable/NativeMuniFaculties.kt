package com.example.muni_timetable

// Mirrors lib/domain/entities/faculty.dart's MuniFaculties.all - kept in sync
// manually since the widget config screen must work without the Flutter engine.
internal data class NativeFaculty(val id: String, val shortName: String, val name: String)

internal object NativeMuniFaculties {
    val all = listOf(
        NativeFaculty("prf", "PrF", "Právnická fakulta"),
        NativeFaculty("med", "LF", "Lékařská fakulta"),
        NativeFaculty("sci", "PřF", "Přírodovědecká fakulta"),
        NativeFaculty("phil", "FF", "Filozofická fakulta"),
        NativeFaculty("ped", "PdF", "Pedagogická fakulta"),
        NativeFaculty("pharm", "FaF", "Farmaceutická fakulta"),
        NativeFaculty("econ", "ESF", "Ekonomicko-správní fakulta"),
        NativeFaculty("fi", "FI", "Fakulta informatiky"),
        NativeFaculty("fss", "FSS", "Fakulta sociálních studií"),
        NativeFaculty("fsps", "FSpS", "Fakulta sportovních studií"),
    )
}

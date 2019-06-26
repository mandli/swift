import CModule
import SwiftModule

func foo(
    _ structDefinedInSwiftModule: StructDefinedInSwiftModule,
    _ structDefinedInSameTarget: StructDefinedInSameTarget
) {
    let a: String = functionDefinedInCModule()
    // CHECK: cannot convert value of type 'Void' to specified type 'String'

    let b: Float = structDefinedInSwiftModule.methodDefinedInSwiftModule()
    // CHECK: cannot convert value of type '()' to specified type 'Float'

    let c: Double = structDefinedInSameTarget.methodDefinedInSameTarget()
    // CHECK: cannot convert value of type '()' to specified type 'Double'
}

// RUN: %empty-directory(%t)
// RUN: %swift -emit-module -o %t/SwiftModule.swiftmodule -module-name SwiftModule %S/../Inputs/vfs/SwiftModule/SwiftModule.swift
// RUN: %sourcekitd-test -req=open -vfs-files=/target_file1.swift=%s,/target_file2.swift=%S/../Inputs/vfs/other_file_in_target.swift,/CModule/module.modulemap=%S/../Inputs/vfs/CModule/module.modulemap,/CModule/CModule.h=%S/../Inputs/vfs/CModule/CModule.h,/SwiftModule/SwiftModule.swiftmodule=%t/SwiftModule.swiftmodule /target_file1.swift -pass-as-sourcetext -- /target_file1.swift /target_file2.swift -I /CModule -I /SwiftModule == \
// RUN:    -req=print-diags -vfs-files=/target_file1.swift=%s,/target_file2.swift=%S/../Inputs/vfs/other_file_in_target.swift,/CModule/module.modulemap=%S/../Inputs/vfs/CModule/module.modulemap,/CModule/CModule.h=%S/../Inputs/vfs/CModule/CModule.h,/SwiftModule/SwiftModule.swiftmodule=%t/SwiftModule.swiftmodule /target_file1.swift  | %FileCheck %s

// RUN: not %sourcekitd-test -req=syntax-map -vfs-files=/target_file1.swift=%s /target_file1.swift -dont-print-request 2>&1 | %FileCheck %s -check-prefix=SOURCEFILE_ERROR
// SOURCEFILE_ERROR: error response (Request Failed): using 'key.sourcefile' to read source text from the filesystem

// RUN: not %sourcekitd-test -req=syntax-map  -vfs-name nope %s -pass-as-sourcetext -dont-print-request 2>&1 | %FileCheck %s -check-prefix=NONEXISTENT_VFS_ERROR
// NONEXISTENT_VFS_ERROR: error response (Request Failed): unknown virtual filesystem 'nope'

// == Close the document and reopen with a new VFS (modules) ==
// RUN: %sourcekitd-test -req=open -vfs-files=/target_file1.swift=%s,/target_file2.swift=%S/../Inputs/vfs/other_file_in_target.swift,/CModule/module.modulemap=%S/../Inputs/vfs/CModule/module.modulemap,/CModule/CModule.h=%S/../Inputs/vfs/CModule/CModule.h,/SwiftModule/SwiftModule.swiftmodule=%t/SwiftModule.swiftmodule /target_file1.swift -pass-as-sourcetext -- /target_file1.swift /target_file2.swift -I /CModule -I /SwiftModule == \
// RUN:    -req=close -name /target_file1.swift == \
// RUN:    -req=open -vfs-files=/target_file1.swift=%s,/target_file2.swift=%S/../Inputs/vfs/other_file_in_target.swift /target_file1.swift -pass-as-sourcetext -- /target_file1.swift /target_file2.swift -I /CModule -I /SwiftModule == \
// RUN:    -req=print-diags -vfs-files=/target_file1.swift=%s /target_file1.swift /target_file1.swift  | %FileCheck %s -check-prefix=NO_MODULES_VFS
// NO_MODULES_VFS: no such module 'CModule'

// == Close the document and reopen with a new VFS (inputs) ==
// RUN: %sourcekitd-test -req=open -vfs-files=/target_file1.swift=%s,/target_file2.swift=%S/../Inputs/vfs/other_file_in_target.swift,/CModule/module.modulemap=%S/../Inputs/vfs/CModule/module.modulemap,/CModule/CModule.h=%S/../Inputs/vfs/CModule/CModule.h,/SwiftModule/SwiftModule.swiftmodule=%t/SwiftModule.swiftmodule /target_file1.swift -pass-as-sourcetext -- /target_file1.swift /target_file2.swift -I /CModule -I /SwiftModule == \
// RUN:    -req=close -name /target_file1.swift == \
// RUN:    -req=open -vfs-files=/target_file1.swift=%s,/target_file2.swift=%S/../Inputs/vfs/other_file_in_target_2.swift,/CModule/module.modulemap=%S/../Inputs/vfs/CModule/module.modulemap,/CModule/CModule.h=%S/../Inputs/vfs/CModule/CModule.h,/SwiftModule/SwiftModule.swiftmodule=%t/SwiftModule.swiftmodule /target_file1.swift -pass-as-sourcetext -- /target_file1.swift /target_file2.swift -I /CModule -I /SwiftModule == \
// RUN:    -req=print-diags -vfs-files=/target_file1.swift=%s /target_file1.swift /target_file1.swift  | %FileCheck %s -check-prefix=TARGET_FILE_2_MOD
// TARGET_FILE_2_MOD: cannot convert value of type 'Void' to specified type 'String'
// TARGET_FILE_2_MOD: cannot convert value of type '()' to specified type 'Float'
// TARGET_FILE_2_MOD: cannot convert value of type 'Int' to specified type 'Double'

// == Reopen with a new VFS without closing ==
// RUN: %sourcekitd-test -req=open -vfs-files=/target_file1.swift=%s,/target_file2.swift=%S/../Inputs/vfs/other_file_in_target.swift,/CModule/module.modulemap=%S/../Inputs/vfs/CModule/module.modulemap,/CModule/CModule.h=%S/../Inputs/vfs/CModule/CModule.h,/SwiftModule/SwiftModule.swiftmodule=%t/SwiftModule.swiftmodule /target_file1.swift -pass-as-sourcetext -- /target_file1.swift /target_file2.swift -I /CModule -I /SwiftModule == \
// RUN:    -req=open -vfs-files=/target_file1.swift=%s,/target_file2.swift=%S/../Inputs/vfs/other_file_in_target_2.swift,/CModule/module.modulemap=%S/../Inputs/vfs/CModule/module.modulemap,/CModule/CModule.h=%S/../Inputs/vfs/CModule/CModule.h,/SwiftModule/SwiftModule.swiftmodule=%t/SwiftModule.swiftmodule /target_file1.swift -pass-as-sourcetext -- /target_file1.swift /target_file2.swift -I /CModule -I /SwiftModule == \
// RUN:    -req=print-diags -vfs-files=/target_file1.swift=%s /target_file1.swift /target_file1.swift  | %FileCheck %s -check-prefix=TARGET_FILE_2_MOD

# Adds boot spec entry for first FSTYPE found
inherit linux-kernel-base

KERNEL_VERSION = "${@get_kernelversion_file("${STAGING_KERNEL_BUILDDIR}")}"

BOOTSPEC_TITLE ?= "${SUMMARY}"
BOOTSPEC_TITLE[doc] = "Content of the boot spec entry 'title' line"

BOOTSPEC_OPTIONS_ext4 = "rootfstype=ext4 rootwait"
BOOTSPEC_OPTIONS_ubi = "rootfstype=ubifs"

BOOTSPEC_VERSION ?= "${KERNEL_VERSION}"
BOOTSPEC_VERSION[doc] ?= "Content of the bootspec version entry"

BOOTSPEC_OPTIONS_DEFAULT = ""

python () {
    option = ""

    for type in (d.getVar('IMAGE_FSTYPES', True) or "").split():
        option = d.getVar('BOOTSPEC_OPTIONS_%s' % type, True)
        if option:
            d.setVar('BOOTSPEC_OPTIONS_DEFAULT', option)
            break;
}

BOOTSPEC_OPTIONS ?= "${BOOTSPEC_OPTIONS_DEFAULT}"
BOOTSPEC_OPTIONS[doc] = "Content of the boot spec entry 'options' line"

BOOTSPEC_EXTRALINE ?= ""
BOOTSPEC_OPTIONS[doc] = "Allows to add extra content to bootspec entries, lines must be terminated with a newline"

python create_bootspec() {
    dtb = d.getVar('KERNEL_DEVICETREE', True).replace('.dtb', '').split()
    bb.utils.mkdirhier(d.expand("${IMAGE_ROOTFS}/loader/entries/"))

    for x in dtb:
        bb.note("Creating boot spec entry /loader/entries/" + x + ".conf ...")

        try:
            bootspecfile = open(d.expand("${IMAGE_ROOTFS}/loader/entries/" + x + ".conf"), 'w')
        except OSError:
            raise bb.build.FuncFailed('Unable to open boot spec file for writing')

        bootspecfile.write('title      %s\n' % d.getVar('BOOTSPEC_TITLE', True))
        bootspecfile.write('version    %s\n' % d.getVar('BOOTSPEC_VERSION', True))
        bootspecfile.write('options    %s\n' % d.expand('${BOOTSPEC_OPTIONS}'))
        bootspecfile.write(d.getVar('BOOTSPEC_EXTRALINE', True).replace(r'\n', '\n'))
        bootspecfile.write('linux      %s\n' % d.expand('/boot/${KERNEL_IMAGETYPE}'))
        bootspecfile.write('devicetree %s\n' % d.expand('/boot/devicetree-${KERNEL_IMAGETYPE}-' + x + '.dtb\n'))

        bootspecfile.close()
}

ROOTFS_POSTPROCESS_COMMAND += " create_bootspec; "

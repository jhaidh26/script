crave run -- no-patch -- '
#!/bin/bash

echo "=========================================================="
echo "🚀 Starting Matrixx Build Script (Verified Links)"
echo "=========================================================="

MAIN_DIR=$(pwd)

# কনফিগারেশন
export USE_CCACHE=0
export NOMINATIVE_CCACHE=1
export SKIP_VENDORSETUP=true

# ক্লিনআপ
echo "Force cleaning corrupted directories..."
rm -rf .repo/local_manifests || true
rm -rf device/oneplus/hotdogb device/oneplus/sm8150-common vendor/oneplus/hotdogb vendor/oneplus/sm8150-common kernel/oneplus/sm8150 hardware/oplus || true

# ৩. Repo initialization (ProjectMatrixx মেইন ম্যানিফেস্ট)
repo init --no-repo-verify --git-lfs -u https://github.com/ProjectMatrixx/android -b 16.2 -g default,-mips,-darwin,-notdefault --depth 1 || true

# ৪. Directory structure
mkdir -p .repo/repo/hooks || true

# ৫. Local manifest clone (আপনার নিজের GitHub রিপোজিটরি)
git clone https://github.com/jhaidh26/local-manifest --depth 1 -b main .repo/local_manifests || true

# ৬. Syncing
echo "Syncing sources..."
/opt/crave/resync.sh || echo "⚠️ Crave resync flagged an issue, but proceeding anyway..."

# প্রি-বিল্ড ও KernelSU ফিক্স
if [ -f "vendor/oneplus/sm8150-common/Android.bp" ]; then
    awk "/name:[[:space:]]*\"prebuilt_\"/ { count++; if (count == 2) { sub(/\"prebuilt_\"/, \"\\\"prebuilt_duplicate_fixed_\\\"\") } } { print }" "vendor/oneplus/sm8150-common/Android.bp" > "vendor/oneplus/sm8150-common/Android.bp.tmp" && mv "vendor/oneplus/sm8150-common/Android.bp.tmp" "vendor/oneplus/sm8150-common/Android.bp" || true
fi

if [ -d "kernel/oneplus/sm8150" ]; then
    cd kernel/oneplus/sm8150
    find arch/arm64/configs/ -type f -name "*defconfig" | while read -r defconfig; do
        sed -i "/CONFIG_KERNELSU/d" "$defconfig" || true
        echo "CONFIG_KERNELSU=y" >> "$defconfig"
    done
    cd "$MAIN_DIR"
fi

# এনভায়রনমেন্ট
export WITH_ADB_INSECURE=true
export SELINUX_IGNORE_NEVERALLOWS=true
export TARGET_GAPPS_PACKAGE_TYPE=true
export TARGET_MULTISIM_CONFIG=dsds
export TARGET_RELEASE=trunk_staging
export ALLOW_MISSING_DEPENDENCIES=true
export ALLOW_RELEASE_CONFIG_MIXED_TYPES=true
export TARGET_RELEASE_CONFIG_BUILD_FLAVOR=default
export BUILD_WITHOUT_SU=true
export OVERRIDE_ANDROID_VERSION_CHECK=true
export WITHOUT_SU=true
export PRODUCT_ARGUMENT_VALIDATION=false
export FORCE_BUILD_NOTICES=false
export SKIP_NOTICE_BUILD=true
export OVERRIDE_NOTICE_FIELDS=true

source build/envsetup.sh || true

# লাঞ্চ কমান্ড (আপনার GitHub রিপোজিটরির AndroidProducts.mk অনুযায়ী এটি সেট করুন)
lunch matrixx_hotdogb-userdebug || echo "⚠️ Lunch failed..."

# বিল্ড
make installclean || true
m bacon -j$(nproc)
'

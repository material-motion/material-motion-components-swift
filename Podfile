workspace 'MaterialMotionComponents.xcworkspace'
use_frameworks!

target "MaterialMotionComponentsCatalog" do
  pod 'CatalogByConvention'
  pod 'Tweaks'
  pod 'MaterialMotionComponents', :path => './'
  pod 'MaterialMotion', :path => '../material-motion-swift/'

  project 'examples/apps/Catalog/MaterialMotionComponentsCatalog.xcodeproj'
end

target "UnitTests" do
  pod 'MaterialMotionComponents', :path => './'

  project 'examples/apps/Catalog/MaterialMotionComponentsCatalog.xcodeproj'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |configuration|
      configuration.build_settings['SWIFT_VERSION'] = "3.0"
      if target.name.start_with?("Material")
        configuration.build_settings['WARNING_CFLAGS'] ="$(inherited) -Wall -Wcast-align -Wconversion -Werror -Wextra -Wimplicit-atomic-properties -Wmissing-prototypes -Wno-sign-conversion -Wno-unused-parameter -Woverlength-strings -Wshadow -Wstrict-selector-match -Wundeclared-selector -Wunreachable-code"
      end
    end
  end
end

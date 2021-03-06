Pod::Spec.new do |s|
  s.name         = "MaterialMotionComponents"
  s.summary      = "Components built with Material Motion."
  s.version      = "1.0.0"
  s.authors      = "The Material Motion Authors"
  s.license      = "Apache 2.0"
  s.homepage     = "https://github.com/material-motion/material-motion-components-swift"
  s.source       = { :git => "https://github.com/material-motion/material-motion-components-swift.git", :tag => "v" + s.version.to_s }
  s.platform     = :ios, "9.0"
  s.requires_arc = true

  s.dependency "MaterialMotion", "~> 2.0"

  s.subspec "VerticalSheetTransition" do |ss|
    ss.source_files = "src/transitions/verticalsheet/*.swift"
  end

  s.subspec "FABMaskedRevealTransition" do |ss|
    ss.source_files = "src/transitions/fab-masked-reveal/*.swift"

    ss.dependency "MaterialMotionComponents/VerticalSheetTransition"
  end
end

import ImageSource
import UIKit
import AVFoundation

final class CameraView: UIView, CameraViewInput, ThemeConfigurable {
    
    typealias ThemeType = MediaPickerRootModuleUITheme
    
    private let accessDeniedView = AccessDeniedView()
    private var cameraOutputView: CameraOutputView?
    private var outputParameters: CameraOutputParameters?
    private var focusIndicator: FocusIndicator?
    private var theme: ThemeType?
    
    // MARK: - Init
    
    init() {
        super.init(frame: .zero)
        
        accessDeniedView.isHidden = true
        
        addSubview(accessDeniedView)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIView
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        accessDeniedView.bounds = bounds
        accessDeniedView.center = bounds.center
        
        cameraOutputView?.frame = bounds
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        let screenSize = bounds.size
        guard screenSize.width != 0 && screenSize.height != 0 && accessDeniedView.isHidden == true  else {
            return
        }
        
        if let touchPoint = touches.first?.location(in: self) {
            let focusOriginX = touchPoint.y / screenSize.height
            let focusOriginY = 1.0 - touchPoint.x / screenSize.width
            let focusPoint = CGPoint(x: focusOriginX, y: focusOriginY)
            
            onFocusTap?(focusPoint, touchPoint)
        }
    }
    
    // MARK: - CameraViewInput
    
    var onFocusTap: ((_ focusPoint: CGPoint, _ touchPoint: CGPoint) -> Void)?
    
    func displayFocus(onPoint focusPoint: CGPoint) {
        focusIndicator?.hide()
        focusIndicator = FocusIndicator()
        if let theme = theme {
            focusIndicator?.setColor(theme.focusIndicatorColor)
        }
        focusIndicator?.animate(in: layer, focusPoint: focusPoint)
    }
    
    var onAccessDeniedButtonTap: (() -> ())? {
        get { return accessDeniedView.onButtonTap }
        set { accessDeniedView.onButtonTap = newValue }
    }
    
    func setAccessDeniedViewVisible(_ visible: Bool) {
        accessDeniedView.isHidden = !visible
    }
    
    func setAccessDeniedTitle(_ title: String) {
        accessDeniedView.title = title
    }
    
    func setAccessDeniedMessage(_ message: String) {
        accessDeniedView.message = message
    }
    
    func setAccessDeniedButtonTitle(_ title: String) {
        accessDeniedView.buttonTitle = title
    }
    
    func setOutputParameters(_ parameters: CameraOutputParameters) {
        
        let newCameraOutputView = CameraOutputView(
            captureSession: parameters.captureSession,
            outputOrientation: parameters.orientation
        )
        
        if let currentCameraOutputView = self.cameraOutputView {
            // AI-3326: костыль для iOS 8.
            // Удаляем предыдущую вьюху, как только будет нарисован первый фрейм новой вьюхи, иначе будет мелькание.
            newCameraOutputView.onFrameDraw = { [weak newCameraOutputView] in
                newCameraOutputView?.onFrameDraw = nil
                DispatchQueue.main.async {
                    currentCameraOutputView.removeFromSuperviewAfterFadingOut(withDuration: 0.25)
                }
            }
        }
        
        addSubview(newCameraOutputView)
        
        self.cameraOutputView = newCameraOutputView
        self.outputParameters = parameters
    }
    
    func setOutputOrientation(_ orientation: ExifOrientation) {
        outputParameters?.orientation = orientation
        cameraOutputView?.orientation = orientation
    }
    
    func mainModuleDidAppear(animated: Bool) {
        // AI-3326: костыль для iOS 8.
        if let outputParameters = outputParameters {
            setOutputParameters(outputParameters)
        }
    }
    
    func adjustForDeviceOrientation(_ orientation: DeviceOrientation) {
        UIView.animate(withDuration: 0.25) {
            self.accessDeniedView.transform = CGAffineTransform(deviceOrientation: orientation)
        }
    }
    
    // MARK: - ThemeConfigurable
    
    func setTheme(_ theme: ThemeType) {
        self.theme = theme
        accessDeniedView.setTheme(theme)
        focusIndicator?.setColor(theme.focusIndicatorColor)
    }
    
    // MARK: - Dispose bag
    
    private var disposables = [AnyObject]()
    
    func addDisposable(_ object: AnyObject) {
        disposables.append(object)
    }
}

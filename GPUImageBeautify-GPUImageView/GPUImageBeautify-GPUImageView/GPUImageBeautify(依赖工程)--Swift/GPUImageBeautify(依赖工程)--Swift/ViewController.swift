//
//  ViewController.swift
//  GPUImageBeautify(依赖工程)--Swift
//
//  Created by Sunniwell on 2016/12/23.
//  Copyright © 2016年 FunWay. All rights reserved.
//

import UIKit


class ViewController: UIViewController, FWBeautifyCameraDelegate {
    var instensityLabel: UILabel?
    var beautifyCamera: FWBeautifyCamera?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        beautifyCamera = FWBeautifyCamera.init(sessionPreset: AVCaptureSessionPreset640x480, cameraPosition: AVCaptureDevicePosition.front, outputImageOrientation: UIInterfaceOrientation.portrait, andCameraView: view)
        beautifyCamera?.delegate = self
        
//        // 设置分辨率
//        beautifyCamera?.sessionPreset = AVCaptureSessionPresetHigh
//        
//        // 设置输出图片的方向
//        beautifyCamera?.outputImageOrientation = UIInterfaceOrientation.unknown
//        
//        // 设置帧数
//        beautifyCamera?.preferFrameRate = 60
//        
//        // 设置磨皮程度
//        beautifyCamera?.intensity = 0.65
//        
//        // 设置亮度（即美白效果）
//        beautifyCamera?.brightness = 1.1
//        
//        // 设置饱和度
//        beautifyCamera?.saturation = 1.1
        
        createUI()
    }
    
    // MARK: 创建UI
    func createUI() {
        // 切换是否使用美颜功能的开关
        let beautifySwitch: UISwitch = UISwitch.init(frame: CGRect.init(x: 50, y: 50, width: 32, height: 16))
        beautifySwitch.setOn(true, animated: true)
        beautifySwitch.addTarget(self, action: #selector(beautifyOrNot(sender:)), for: UIControlEvents.valueChanged)
        view.addSubview(beautifySwitch)
        beautifySwitch.mas_makeConstraints { (maker) in
            maker?.right.equalTo()(self.view)?.setOffset(32)
            maker?.top.equalTo()(self.view)?.setOffset(-32)
            _ = maker?.width.equalTo()(32)
            _ = maker?.height.equalTo()(16)
        }
        
        // 转换前后置摄像头的按钮
        let toggleCameraButton: UIButton = UIButton.init(type: UIButtonType.system)
        toggleCameraButton.setTitle("前置", for: UIControlState.selected)
        toggleCameraButton.setTitle("后置", for: UIControlState.normal)
        toggleCameraButton.isSelected = true
        toggleCameraButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        toggleCameraButton.addTarget(self, action: #selector(toggleCamera(sender:)), for: UIControlEvents.touchUpInside)
        view.addSubview(toggleCameraButton)
        toggleCameraButton.mas_makeConstraints { (maker) in
            _ = maker?.top.equalTo()(self.view)?.offset()(32)
            _ = maker?.left.equalTo()(self.view)?.offset()(16)
            _ = maker?.width.equalTo()(48)
            _ = maker?.height.equalTo()(32)
        }
    
        // 调节 intensity 的滑块，即磨皮程度
        let intensitySlider: UISlider = UISlider.init(frame: view.frame)
        intensitySlider.maximumValue = 1
        intensitySlider.minimumValue = 0
        intensitySlider.value = 0.5
        intensitySlider.addTarget(self, action: #selector(intensityValueChange(sender:)), for: UIControlEvents.valueChanged)
        view.addSubview(intensitySlider)
        intensitySlider.mas_makeConstraints { (maker) in
            _ = maker?.bottom.equalTo()(self.view)?.offset()(-32)
            _ = maker?.left.equalTo()(self.view)?.offset()(16)
            _ = maker?.trailing.equalTo()(self.view)?.offset()(-16)
        }
        
        // 磨皮程度指数
        let intensityLabel: UILabel = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: 100, height: 36))
        intensityLabel.textColor = UIColor.darkGray
        intensityLabel.font = UIFont.boldSystemFont(ofSize: 24)
        intensityLabel.text = "0.50"
        intensityLabel.textAlignment = NSTextAlignment.center
        view.addSubview(intensityLabel)
        intensityLabel.mas_makeConstraints { (maker) in
            _ = maker?.bottom.equalTo()(intensitySlider)?.offset()(-32)
            _ = maker?.centerX.equalTo()(intensitySlider)
            _ = maker?.width.equalTo()(64)
            _ = maker?.height.equalTo()(32)
        }
        
        // 开始、停止视频
        let segmentControl: UISegmentedControl = UISegmentedControl.init(items: ["开始", "停止"])
        segmentControl.frame = CGRect(x: 0, y: 0, width: 30, height: view.frame.height)
        segmentControl.selectedSegmentIndex = 0
        segmentControl.addTarget(self, action: #selector(segmentValueChange(sender:)), for: UIControlEvents.valueChanged)
        view .addSubview(segmentControl)
        segmentControl.mas_makeConstraints { (maker) in
            _ = maker?.top.equalTo()(self.view)?.offset()(32)
            _ = maker?.centerX.equalTo()(intensitySlider)
            _ = maker?.width.equalTo()(128)
        }
    }
    
    // MARK: - Action
    // MARK: 切换是否使用美颜功能
    func beautifyOrNot(sender: UISwitch) -> Void {
        beautifyCamera?.switchBeauty(sender.isOn)
        sender.isOn = !sender.isOn
    }
    
    // MARK: 切换前后置摄像头
    func toggleCamera(sender:UIButton) -> Void {
        beautifyCamera?.toggle()
        sender.isSelected = !sender.isSelected
    }
    
    // MARK: 调整磨皮效果(instensity)
    func intensityValueChange(sender: UISlider) -> Void {
        beautifyCamera?.intensity = CGFloat(sender.value)
        instensityLabel?.text = NSString.init(format: "%.2f", sender.value) as String
    }
    
    // MARK: 开关直播
    func segmentValueChange(sender: UISegmentedControl) -> Void {
        if sender.selectedSegmentIndex == 0 {
            beautifyCamera?.startRunning()
        } else {
            beautifyCamera?.stopRunning()
        }
    }
    
    // MARK: - FWBeautifyCompareDelegate
    func onBeautifyCamera(_ camera: FWBeautifyCamera!, andPixelBuffer pixelBuffer: CVPixelBuffer!) {
        print("Pixel buffer size: \(String(format:"%zu", CVPixelBufferGetWidth(pixelBuffer))) - \(String(format:"%zu", CVPixelBufferGetHeight(pixelBuffer)))")
        
        // 将 pixelBuffer 用于编码或推流
        /*
        // 示例代码
        // 注意：iOS 8.x 上无法本地显示，但数据没有问题
        let ciImage: CIImage = CIImage.init(cvPixelBuffer: pixelBuffer)
        
        let temporaryContext:CIContext = CIContext.init(options: nil)
        let videoImage: CGImage = temporaryContext.createCGImage(ciImage, from: CGRect.init(x: 0, y: 0, width: CVPixelBufferGetWidth(pixelBuffer), height: CVPixelBufferGetHeight(pixelBuffer)))!
        
        let uiImage: UIImage = UIImage.init(cgImage: videoImage)
        
        performSelector(onMainThread: #selector(updatePreview(image:)), with: uiImage, waitUntilDone: false)
         */
    }
    
    /*
    func updatePreview(image: UIImage) -> Void {
        let previewView: UIImageView = UIImageView.init(frame: CGRect.init(x: 30, y: 60, width: 160, height: 200))
        previewView.contentMode = UIViewContentMode.scaleAspectFit
        previewView.image = image
        view.addSubview(previewView)
        
        previewView.setNeedsDisplay()
    }
    */

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}


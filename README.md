# 电子设计小学期
## 整体工作
- Part 1
    - 在上位机控制下小车完成相关运动
    - 小车安装摄像头，将实时图像回传给上位机  
- Part 2
    - 小车完成相对位置信息的记录和回传
    - 利用位置信息进行
        - 二维地图的展示
        - 结合图像进行三维重建
- Part 3
    - 应用部署到移动平台
    - 小车安装避障自动运行

## TODOs（完成注明完成者）
- [ ] 小车硬件部分
    - [ ] 电源模块3V3，5，Webench上的开发工作
    - [ ] PCB
    - [ ] bts驱动调整
    - [x] 舵机调整，测试*Archer@20170808*
    - [ ] IMU，码盘等传感器安装和调试
- [ ] FPGA部分（包含可能采用myRIO代替的工作）
    - [x] 蓝牙信道的测试
        - 基于HC-05蓝牙转串口模块与上位机通信 ~~，有误码现象，需改进~~。*Archer@20170731*
    - [x] OV7670初始化和数据读取
        - `commit 9108e93` VCC3.3，SCL和SDA接4.7k上拉电阻，输出速度受串口限制。*Archer@20170804*
    - [ ] IMU，码盘信息的采集和处理（可能使用myRIO主控）
- [ ] 上位机部分（包含可能的移动平台部署）
    - [x] 蓝牙信道的测试
        - HC-05模块已设置为slave模式，上位机通过蓝牙连接后使用串口助手即可双向通信。*Archer@20170731*
    - [x] UI开发，整体架构 *ZeroWeight@20170805*
    - [ ] 3D recon的处理
    - [ ] 移动平台的部署
- [ ] 报告
    - [ ] 预习报告
        - [ ] 选题背景及课题简介
        - [ ] 方案比较与选择（参考文献评述）
        - [ ] 基于FPGA的数字系统框图
        - [ ] 传感器/执行机构接口电路图
        - [ ] 基于Webench的电源电路仿真
    - [ ] 选题展示PPT
    - [ ] 总结报告
        - [ ] 课题开发与调试中出现的问题分析
        - [ ] 创新点（如有）
        - [ ] 附完整源码
        - [ ] 工作日志
        - [ ] 作品的视频
    - [ ] 最终展示PPT

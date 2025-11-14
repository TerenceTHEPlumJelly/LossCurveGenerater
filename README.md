# LossCurveGenerater
---
一个可以基于特定模式日志绘制损失曲线并存为fig文件的生成器

模式如下：

    时间戳：10/04/2025 02:29:58
    
    GlobalStep：72001
    
    loss_noise_mse
    
    loss_fk_mse
    
    loss_depth
    
    total_loss

模式实例：Rank[0/1] 10/04/2025 02:29:58 INFO loss_tracker.py:141 | Epoch[33/NA] Step[424] GlobalStep[72001/99999]: loss_noise_mse[0.0000]	loss_fk_mse[0.0046]	loss_depth[0.0129]	total_loss[0.0176]

基于ChatGPT生成

## LossCurveWithoutName.m
基础功能

## LossCurve.m
可以随输入日志文件命名修改输出的fig名称的版本

## LossCurveTimeStep.m
修改了时间轴的版本

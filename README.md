设计简介
---------------

本次个人赛所提交的设计是一个含有SRAM控制器、UART控制器、CPU内核三大部分的SOC系统。其中CPU内核是基于MIPS指令集的，能够支持MIPS的34条指令。CPU的架构采用传统的单发射五级流水线，能够完成三级功能测试的基本要求，并且能够比较快地完成三级性能测试。

为了对CPU进行加速，本设计作出了两大尝试。一是尝试在UART控制器中引入FIFO，希望能够对串口进行优化。二是借鉴网上的优秀代码，自行设计了一个32位基4 booth乘法器。

具体实现详情可以参考设计手册design.pdf。
  

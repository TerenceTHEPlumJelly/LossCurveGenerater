%% === LossCurve_fromLog.m ===
% 读取日志文件并绘制loss曲线
% 作者: ChatGPT (GPT-5)
% 日期: 2025-10-04
% 示例启动指令：run('.\LossCurve.m')

clc; clear; close all;

%% === 1. 配置路径 ===
log_path = '.\train_real.log';  % 修改为你的日志路径

%% === 2. 读取整个文件 ===
fid = fopen(log_path, 'r');
if fid == -1
    error('无法打开日志文件: %s', log_path);
end
raw_text = textscan(fid, '%s', 'Delimiter', '\n', 'Whitespace', '');
fclose(fid);
lines = raw_text{1};

%% === 3. 定义正则表达式 ===
% 示例行：
% 10/04/2025 02:29:58 ... GlobalStep[72001/99999]: loss_noise_mse[0.0000] loss_fk_mse[0.0046] loss_depth[0.0129] total_loss[0.0176]
pattern = '(\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2}).*?GlobalStep\[(\d+)/\d+\]: loss_noise_mse\[(.*?)\]\s+loss_fk_mse\[(.*?)\]\s+loss_depth\[(.*?)\]\s+total_loss\[(.*?)\]';

%% === 4. 初始化数据容器 ===
time_list = {};
step_list = [];
loss_noise_mse = [];
loss_fk_mse = [];
loss_depth = [];
total_loss = [];

%% === 5. 逐行解析 ===
for i = 1:length(lines)
    tokens = regexp(lines{i}, pattern, 'tokens');
    if ~isempty(tokens)
        tok = tokens{1};
        % 提取字段
        t_str = tok{1};
        step_list(end+1,1) = str2double(tok{2});
        loss_noise_mse(end+1,1) = str2double(tok{3});
        loss_fk_mse(end+1,1) = str2double(tok{4});
        loss_depth(end+1,1) = str2double(tok{5});
        total_loss(end+1,1) = str2double(tok{6});

        % 解析时间戳
        time_list{end+1,1} = datetime(t_str, 'InputFormat', 'MM/dd/yyyy HH:mm:ss');
    end
end

if isempty(time_list)
    error('日志中未找到匹配的 GlobalStep 数据。');
end

%% === 6. 转换时间为秒（相对起始时间）===
time_dt = [time_list{:}]';
time_seconds = seconds(time_dt - time_dt(1));

%% === 7. 绘制曲线 ===
figure('Color','w','Position',[100 100 800 500]);
plot(time_seconds, loss_noise_mse, 'LineWidth', 1.5); hold on;
plot(time_seconds, loss_fk_mse, 'LineWidth', 1.5);
plot(time_seconds, loss_depth, 'LineWidth', 1.5);
plot(time_seconds, total_loss, 'LineWidth', 1.5);
grid on;
xlabel('Time (s)');
ylabel('Loss Value');
title('Loss Curves Over Time');
legend({'loss\_noise\_mse','loss\_fk\_mse','loss\_depth','total\_loss'}, 'Location','northeast');
set(gca, 'FontSize', 12);

%% === 8. 根据日志文件名生成输出文件名 ===
[~, baseName, ~] = fileparts(log_path);
fig_name = sprintf('%s_LossCurve.fig', baseName);
mat_name = sprintf('%s_LossCurve.mat', baseName);

%% === 9. 保存结果 ===
save(mat_name, 'time_seconds', 'step_list', ...
    'loss_noise_mse', 'loss_fk_mse', 'loss_depth', 'total_loss');
savefig(fig_name);

fprintf('✅ 已保存:\n  %s\n  %s\n', mat_name, fig_name);

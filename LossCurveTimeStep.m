% 解析 train_real.log 中的 GlobalStep 与四种 loss 并绘图
% 底轴: GlobalStep
% 顶轴: 对应时间
% 输出: <logname>_LossCurve.fig/.mat
%
% 作者: ChatGPT (GPT-5)
% 日期: 2025-10-05
% run('LossCurveTimeStep.m')

clc; clear; close all;

%% === 1. 配置路径 ===
log_path = '.\train_real.log';   % 修改为你的日志文件路径

%% === 2. 读取日志 ===
fid = fopen(log_path,'r');
if fid == -1
    error('无法打开日志文件: %s', log_path);
end
raw = textscan(fid,'%s','Delimiter','\n','Whitespace','');
fclose(fid);
lines = raw{1};
fprintf('读取到 %d 行日志。\n', numel(lines));

%% === 3. 探测 step_log_freq ===
step_log_freq = 25;  % 默认
for i = 1:min(800,numel(lines))
    t = regexp(lines{i}, '"step_log_freq"\s*:\s*(\d+)', 'tokens', 'once');
    if ~isempty(t)
        step_log_freq = str2double(t{1});
        break;
    end
end

%% === 4. 正则定义 ===
stepPat  = 'GlobalStep\[(\d+)(?:/\d+)?\]';
timePat  = '(\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2})';
floatPat = '([-+]?\d*\.?\d+(?:[eE][-+]?\d+)?)';
p_noise  = ['loss_noise_mse\[' floatPat '\]'];
p_fk     = ['loss_fk_mse\['    floatPat '\]'];
p_depth  = ['loss_depth\['     floatPat '\]'];
p_total  = ['total_loss\['     floatPat '\]'];

%% === 5. 初始化 ===
step_all = [];
loss_noise_all = []; loss_fk_all = []; loss_depth_all = []; total_loss_all = [];
time_all = datetime.empty(0,1);

%% === 6. 解析行 ===
for i = 1:numel(lines)
    ln = lines{i};
    if contains(ln,'GlobalStep') && contains(ln,'loss_noise_mse')
        s = regexp(ln, stepPat, 'tokens','once');
        if isempty(s), continue; end
        step_val = str2double(s{1});

        % 时间
        tm = regexp(ln,timePat,'tokens','once');
        if ~isempty(tm)
            try
                tdt = datetime(tm{1},'InputFormat','MM/dd/yyyy HH:mm:ss');
            catch
                tdt = NaT;
            end
        else
            tdt = NaT;
        end

        % 各 loss
        v1 = NaN; v2 = NaN; v3 = NaN; v4 = NaN;
        t1 = regexp(ln,p_noise,'tokens','once'); if ~isempty(t1), v1 = str2double(t1{1}); end
        t2 = regexp(ln,p_fk,'tokens','once');    if ~isempty(t2), v2 = str2double(t2{1}); end
        t3 = regexp(ln,p_depth,'tokens','once'); if ~isempty(t3), v3 = str2double(t3{1}); end
        t4 = regexp(ln,p_total,'tokens','once'); if ~isempty(t4), v4 = str2double(t4{1}); end

        step_all(end+1,1) = step_val;
        loss_noise_all(end+1,1) = v1;
        loss_fk_all(end+1,1)    = v2;
        loss_depth_all(end+1,1) = v3;
        total_loss_all(end+1,1) = v4;
        time_all(end+1,1)       = tdt;
    end
end

if isempty(step_all)
    error('❌ 未解析到任何 loss 记录，请检查日志格式。');
end
fprintf('✅ 成功解析 %d 条 loss 记录。\n', numel(step_all));

%% === 7. 去重并排序 ===
[steps, ia] = unique(step_all,'last');
[steps, ord] = sort(steps);
ln_vec = loss_noise_all(ia(ord));
lf_vec = loss_fk_all(ia(ord));
ld_vec = loss_depth_all(ia(ord));
lt_vec = total_loss_all(ia(ord));
times  = time_all(ia(ord));

%% === 8. 绘图 (底轴 step，顶轴时间) ===
h = figure('Color','w','Position',[100 100 1100 600]); hold on;
plot(steps, ln_vec, '-','LineWidth',1.2);
plot(steps, lf_vec, '-','LineWidth',1.2);
plot(steps, ld_vec, '-','LineWidth',1.2);
plot(steps, lt_vec, '-','LineWidth',1.6);
grid on;
xlabel('GlobalStep','FontSize',12);
ylabel('Loss','FontSize',12);
legend({'loss\_noise\_mse','loss\_fk\_mse','loss\_depth','total\_loss'}, 'Location','northeast');
set(gca,'FontSize',11);

% ---- 顶部时间刻度 ----
validMask = ~isnat(times);
if sum(validMask) >= 2
    nTicks = 6;
    tickSteps = round(linspace(steps(1), steps(end), nTicks));
    secs = seconds(times - times(find(validMask,1)));
    secTicks = interp1(steps(validMask), secs(validMask), tickSteps, 'linear','extrap');
    baseTime = times(find(validMask,1));
    tLabels = cellstr(datestr(baseTime + seconds(secTicks),'mm-dd HH:MM:SS'));

    ax = gca; ax_pos = ax.Position;
    ax2 = axes('Position',ax_pos,'XAxisLocation','top','YAxisLocation','right','Color','none');
    set(ax2,'XLim',ax.XLim,'YTick',[],'XTick',tickSteps,'XTickLabel',tLabels,'FontSize',9);
    linkaxes([ax ax2],'x');
end

[~, baseName, ~] = fileparts(log_path);
title(sprintf('%s Loss Curves (step bottom, time top)', baseName),'Interpreter','none');

%% === 9. 保存 ===
fig_name = sprintf('%s_LossCurve.fig', baseName);
mat_name = sprintf('%s_LossCurve.mat', baseName);
savefig(h, fig_name);
save(mat_name,'steps','times','ln_vec','lf_vec','ld_vec','lt_vec',...
              'loss_noise_all','loss_fk_all','loss_depth_all','total_loss_all','step_all');
fprintf('💾 已保存文件：\n  %s\n  %s\n', fig_name, mat_name);

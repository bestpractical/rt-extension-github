use inc::Module::Install;

RTx     'RT-Extension-GitHub';
license 'gpl_2';
repository 'https://github.com/bestpractical/rt-extension-github';

requires_rt '5.0.0';
rt_too_new '5.2.0';

sign;
WriteAll;

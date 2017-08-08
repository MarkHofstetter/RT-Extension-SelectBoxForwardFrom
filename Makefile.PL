use inc::Module::Install;

RTx     'RT-Extension-SelectBoxForwardFrom';
license 'gplv2';
repository 'https://github.com/bestpractical/rt-extension-selectboxforwardfrom';

requires_rt '4.0.0';
rt_too_new '4.6.0';

sign;
WriteAll;

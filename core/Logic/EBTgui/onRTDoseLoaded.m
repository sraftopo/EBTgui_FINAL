% This function is raised when an RTDose is loaded, in order
% to define global variables that are related it
function onRTDoseLoaded()

  EBTSceneController = GetGlobalVar('EBTSceneController');

  doseCube = EBTSceneController.TPSRTDose.mDoseCube;

  [I1, I2, I3] = ind2sub(size(doseCube),find(doseCube == max(doseCube(:))));
  SetGlobalVar('MaxTPSDose',double(max(doseCube(:)))*EBTSceneController.TPSRTDose.mDoseGridScaling);
  SetGlobalVar('MaxTPSDoseOriginal', GetGlobalVar('MaxTPSDose'));
  SetGlobalVar('MaxTPSPosition',[I1(1), I2(1),I3(1)]);
  
end

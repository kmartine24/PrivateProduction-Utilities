import FWCore.ParameterSet.Config as cms

externalLHEProducer = cms.EDProducer("ExternalLHEProducer",
        #Justin's: args = cms.vstring("../../../pp_eemm-cHWB_massless_slc7_amd64_gcc10_CMSSW_12_3_0_tarball.tar.xz"),
        #from McM: args = cms.vstring('/cvmfs/cms.cern.ch/phys_generator/gridpacks/PdmV/Run3Summer22/Powheg/ZZ/ZZ_slc7_amd64_gcc10_CMSSW_12_4_8_ZZto4L_powheg-pythia8.tgz'), 
        #Mine:
        args = cms.vstring('../../../../WZto3LNu-WpolTransversal-ZpolTransversal_el9_amd64_gcc11_CMSSW_15_0_19_tarball.tar.xz'),
		nEvents = cms.untracked.uint32(5000),
		numberOfParameters = cms.uint32(1),
		outputFile = cms.string('cmsgrid_final.lhe'),
		scriptName = cms.FileInPath('GeneratorInterface/LHEInterface/data/run_generic_tarball_cvmfs.sh'),
        generateConcurrently = cms.untracked.bool(True),
		)
from Configuration.Generator.Pythia8CommonSettings_cfi import *
from Configuration.Generator.MCTunesRun3ECM13p6TeV.PythiaCP5Settings_cfi import *
from Configuration.Generator.Pythia8PowhegEmissionVetoSettings_cfi import *
from Configuration.Generator.PSweightsPythia.PythiaPSweightsSettings_cfi import *

generator = cms.EDFilter("Pythia8ConcurrentHadronizerFilter", #Justin's: cms.EDFilter("Pythia8HadronizerFilter",
		PythiaParameters = cms.PSet(
			pythia8CommonSettingsBlock,
			pythia8CP5SettingsBlock,     
            pythia8PowhegEmissionVetoSettingsBlock,
            pythia8PSweightsSettingsBlock,
            processParameters = cms.vstring(
            'POWHEG:nFinal = 2',
            'TimeShower:mMaxGamma = 4.0'
            ),
#			pythia8CUEP8M1SettingsBlock,
#			processParameters = cms.vstring(
#				),
			parameterSets = cms.vstring(
				'pythia8CommonSettings',
				'pythia8CP5Settings',
                'pythia8PowhegEmissionVetoSettings',
                'processParameters',
				'pythia8PSweightsSettings',
				#'pythia8CUEP8M1Settings',
				#'processParameters'
				)
			),
		comEnergy = cms.double(13600.),
		maxEventsToPrint = cms.untracked.int32(1),
        pythiaHepMCVerbosity = cms.untracked.bool(False),
		pythiaPylistVerbosity = cms.untracked.int32(1),
        #Justin's: filterEfficiency = cms.untracked.double(1.0),
        #Justin's: pythiaHepMCVerbosity = cms.untracked.bool(False),

		)

#Justin's: ProductionFilterSequence = cms.Sequence(generator)

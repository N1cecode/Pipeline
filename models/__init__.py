import importlib, os
from copy import deepcopy
from os import path as osp

from utils import get_root_logger, scandir
from utils.registry import MODEL_REGISTRY

__all__ = ['build_model']

# automatically scan and import model modules for registry
# scan all the files under the 'models' folder and collect files ending with '_model.py'
model_folder = osp.dirname(osp.abspath(__file__))
model_filenames = [osp.splitext(osp.basename(v))[0] for v in scandir(model_folder) if v.endswith('_model.py')]
# import all the model modules
_model_modules = [importlib.import_module(f'models.{file_name}') for file_name in model_filenames]


def build_model(opt, arch):
    """Build model from options.

    Args:
        opt (dict): Configuration. It must contain:
            model_type (str): Model type.
    """
    opt = deepcopy(opt)
    model = MODEL_REGISTRY.get(opt['model_type'])(opt, arch)
    logger = get_root_logger()
    logger.info(f'Model [{model.__class__.__name__}] is created.')
    return model


def build_arch(folder_path, opt):
    # Scan the folder for yaml and arch files
    files = os.listdir(folder_path)
    arch_files = [f for f in files if f.endswith('.py')]
    
    # Load arch file
    if len(arch_files) > 0:
        spec = importlib.util.spec_from_file_location("arch", os.path.join(folder_path, arch_files[0]))
        arch_module = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(arch_module)
        
        # Get the class name from the yaml config and instantiate the class
        network_opt = opt['network_g'].copy()
        class_name = network_opt.pop('type')
        hyperparameters = network_opt
        if class_name:
            arch_class = getattr(arch_module, class_name)
            arch = arch_class(**hyperparameters)  # instantiate the network class with hyperparameters
        else:
            raise ValueError('Class name not found in the yaml config.')
    else:
        raise FileNotFoundError('No arch file found in the specified folder.')
    
    return arch
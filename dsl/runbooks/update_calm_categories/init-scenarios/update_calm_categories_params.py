import os
from calm.dsl.builtins import *
from calm.dsl.config import get_context

variable_list = [
   { "value": os.getenv("CALM_CATEGORIES_LIST"), "context": "Default", "name": "categories_list" }
]
const { diff_match_patch } = require("diff-match-patch");
const dmp = new diff_match_patch();

export const diffMatchPatch = {
  diff_main: (...args) => {
    try {
      const diff = dmp.diff_main(...args);
      dmp.diff_cleanupSemantic(diff);
      return diff;
    } catch (err) {
      return new Error(err);
    }
  },
  patch_make: (...args) => {
    try {
      const result = dmp.patch_make(...args);
      return result;
    } catch (err) {
      return new Error(err);
    }
  },
  patch_apply: (...args) => {
    try {
      const result = dmp.patch_apply(...args);
      return result;
    } catch (err) {
      return new Error(err);
    }
  },
};

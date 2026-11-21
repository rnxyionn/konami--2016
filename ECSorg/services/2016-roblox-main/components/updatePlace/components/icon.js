import updatePlaceStore from "../stores/updatePlaceStore";
import {useEffect, useRef, useState} from "react";
import {multiGetUniverseIcons} from "../../../services/thumbnails";
import {uploadGameIcon} from "../../../services/games";
import ActionButton from "../../actionButton";
import useButtonStyles from "../../../styles/buttonStyles";

const Icon = props => {
  const store = updatePlaceStore.useContainer();
  const fileRef = useRef(null);
  const buttonStyles = useButtonStyles();
  const [icon, setIcon] = useState(null);
  const [uploading, setUploading] = useState(false);
  const [feedback, setFeedback] = useState(null);

  const loadIcon = () => {
    multiGetUniverseIcons({universeIds: [store.details.universeId], size: '420x420'}).then(img => {
      setIcon(img.length ? img[0].imageUrl : null);
    }).catch(e => {
      setFeedback(e.message);
    });
  };

  useEffect(() => {
    if (store.details?.universeId)
      loadIcon();
  }, [store.details?.universeId]);

  const upload = async () => {
    const file = fileRef.current?.files?.[0];
    if (uploading) return;
    if (!file) {
      setFeedback('Choose a PNG or JPEG image first.');
      return;
    }

    setUploading(true);
    setFeedback(null);
    try {
      await uploadGameIcon({universeId: store.details.universeId, file});
      setFeedback('Icon uploaded and waiting for moderation.');
      fileRef.current.value = '';
    } catch (e) {
      setFeedback(e.response?.data?.errors?.[0]?.message || e.message);
    } finally {
      setUploading(false);
    }
  };

  return <div className='row mt-4'>
    <div className='col-12'>
      <h2 className='fw-bolder mb-4'>Game Icon</h2>
      {feedback ? <p className='mb-2'>{feedback}</p> : null}
    </div>
    <div className='col-6'>
      <img className='w-100 mx-auto d-block' src={icon || '/img/placeholder.png'} alt='Your game icon' />
      <input ref={fileRef} className='mt-3' type='file' accept='image/png,image/jpeg' />
      <div className='mt-3'>
        <ActionButton
          disabled={uploading}
          className={buttonStyles.normal + ' ' + buttonStyles.continueButton}
          label={uploading ? 'Uploading...' : 'Upload Icon'}
          onClick={upload}
        />
      </div>
    </div>
  </div>
}

export default Icon;